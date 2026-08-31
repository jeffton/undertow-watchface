Skip comments.

Use typing for everything the compiler permits. Monkey C 3.4 rejects explicit typing of local variables, so let local variable types be inferred.

## Linux build environment

This server has:

- Connect IQ SDK 9.2.0 in `/root/.Garmin/ConnectIQ/Sdks/`
- Instinct 2 device support in `/root/.Garmin/ConnectIQ/Devices/instinct2/`
- `monkeyc` and `monkeydo` wrappers in `/usr/local/bin/`
- a local sideload signing key at `/root/.Garmin/ConnectIQ/Keys/developer_key.der`
- `connect-iq-sdk-manager` 0.8.4 installed for headless SDK/device management

Check the latest stable SDK on Garmin's official SDK page before installing a version. The official Linux SDK Manager requires a GUI; use `connect-iq-sdk-manager` for headless setup:

```bash
connect-iq-sdk-manager agreement view
connect-iq-sdk-manager agreement accept --agreement-hash=<current-hash>
connect-iq-sdk-manager sdk set <latest-stable-version>
```

Download device support from the manifest:

```bash
connect-iq-sdk-manager device download --manifest=manifest.xml
```

Generate a local signing key if it is missing:

```bash
mkdir -p /root/.Garmin/ConnectIQ/Keys
umask 077
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out /tmp/garmin-key.pem
openssl pkcs8 -topk8 -inform PEM -outform DER -in /tmp/garmin-key.pem \
  -out /root/.Garmin/ConnectIQ/Keys/developer_key.der -nocrypt
rm /tmp/garmin-key.pem
```

## Configuration

`source/background/WakeServiceSettings.mc` is ignored by Git. For a compile-only build, copy the empty template:

```bash
cp source/background/WakeServiceSettings.mc.template source/background/WakeServiceSettings.mc
```

For a usable sideload build, generate it from the deployed Wake configuration without printing the API key:

```bash
python3 - <<'PY'
import json
from pathlib import Path
options = json.load(open('/etc/wake-service/options.json'))
key = next(item['key'] for item in options['apiKeys'] if item['type'] == 'full')
Path('source/background/WakeServiceSettings.mc').write_text(
    'import Toybox.Lang;\n\n(:background)\nmodule WakeServiceSettings {\n'
    '  const URL as String = "https://wake.roybot.se/sync";\n'
    f'  const API_KEY as String = "{key}";\n'
    '}\n'
)
PY
```

Never commit this generated file.

## Build

Always compile after changes:

```bash
mkdir -p bin
monkeyc -o bin/Undertow.prg \
  -f monkey.jungle \
  -y /root/.Garmin/ConnectIQ/Keys/developer_key.der \
  -d instinct2_sim \
  -l 1 \
  -w
```

Build a sideloadable release with the real Wake configuration:

```bash
mkdir -p dist
monkeyc -o dist/Undertow.prg \
  -f monkey.jungle \
  -y /root/.Garmin/ConnectIQ/Keys/developer_key.der \
  -d instinct2_sim \
  -l 1 \
  -w \
  -r
```

`bin/`, `dist/`, and `source/background/WakeServiceSettings.mc` are ignored and must remain uncommitted.

## Simulator and screenshots

Ubuntu 24.04 lacks the legacy GTK/WebKit libraries required by Garmin's simulator. Run it headlessly in the local `garmin-connectiq-sim:22.04` Docker image with Xvfb. Rebuild that image if missing:

```bash
docker build -t garmin-connectiq-sim:22.04 - <<'EOF'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && apt-get install -y -qq \
  openjdk-17-jre-headless xvfb imagemagick xdotool openbox dbus-x11 \
  libsecret-1-0 libwebkit2gtk-4.0-37 libjavascriptcoregtk-4.0-18 libsoup2.4-1 \
  libxkbcommon0 libsm6 libgtk-3-0 libusb-1.0-0 \
  && rm -rf /var/lib/apt/lists/*
EOF
```

Install simulator fonts with the device package. The Garmin API cannot download the three generic Bitstream filenames containing spaces, so local aliases use the corresponding Garmin fonts:

```bash
connect-iq-sdk-manager device download --manifest=manifest.xml --include-fonts
F=/root/.Garmin/ConnectIQ/Fonts
cp "$F/FNT_006B388800_0000_GARMIN_16.cft" "$F/bitstreamVeraSans 16.cft"
cp "$F/FNT_006B388800_0000_GARMIN_20.cft" "$F/bitstreamVeraSans 21.cft"
cp "$F/FNT_006B388800_0000_GARMIN_30.cft" "$F/bitstreamVeraSans 27.cft"
```

The debug build uses `DemoModelsRepository`, making it suitable for deterministic visual screenshots. Build it first, then run and capture it:

```bash
set -euo pipefail
rm -rf /tmp/undertow-simulator
mkdir -p /tmp/undertow-simulator
docker rm -f undertow-simulator 2>/dev/null || true
cleanup() { docker rm -f undertow-simulator >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker run -d --rm --network none --name undertow-simulator \
  -v /root/.Garmin/ConnectIQ/Sdks:/root/.Garmin/ConnectIQ/Sdks:ro \
  -v /root/.Garmin/ConnectIQ/Devices:/root/.Garmin/ConnectIQ/Devices:ro \
  -v /root/.Garmin/ConnectIQ/Fonts:/root/.Garmin/ConnectIQ/Fonts:ro \
  -v "$PWD/bin":/app/bin:ro \
  -v /tmp/undertow-simulator:/out \
  garmin-connectiq-sim:22.04 bash -lc '
    export DISPLAY=:99
    SDK=/root/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-9.2.0-2026-06-09-92a1605b2
    Xvfb :99 -screen 0 1280x1024x24 -nolisten tcp >/out/xvfb.log 2>&1 &
    openbox >/out/openbox.log 2>&1 &
    "$SDK/bin/simulator" >/out/simulator.log 2>&1 &
    sleep infinity
  ' >/dev/null

ready=false
for _ in $(seq 1 30); do
  if docker exec undertow-simulator bash -lc \
    'export DISPLAY=:99; xdotool search --name "CIQ Simulator" >/dev/null'; then
    ready=true
    break
  fi
  sleep 1
done
[ "$ready" = true ]

docker exec undertow-simulator bash -lc '
  export DISPLAY=:99
  SDK=/root/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-9.2.0-2026-06-09-92a1605b2
  "$SDK/bin/monkeydo" /app/bin/Undertow.prg instinct2 >/out/monkeydo.log 2>&1 &
'

ready=false
for _ in $(seq 1 30); do
  geometry=$(docker exec undertow-simulator bash -lc \
    'export DISPLAY=:99; xdotool search --name "CIQ Simulator" getwindowgeometry --shell')
  if grep -q '^HEIGHT=554$' <<<"$geometry"; then
    ready=true
    break
  fi
  sleep 1
done
[ "$ready" = true ]

docker exec undertow-simulator bash -lc '
  export DISPLAY=:99
  WINDOW=$(xdotool search --name "CIQ Simulator" | head -1)
  import -display :99 -window "$WINDOW" /out/simulator-window.png
  convert /out/simulator-window.png -crop 176x176+100+190 +repage /out/watch-screen.png
'
test -s /tmp/undertow-simulator/simulator-window.png
test -s /tmp/undertow-simulator/watch-screen.png

docker stop undertow-simulator >/dev/null
trap - EXIT
```

Screenshots are written to `/tmp/undertow-simulator/`. The measured runtime footprint is about 110 MB of Docker working-set RAM, or roughly 340 MB summed process RSS including shared mappings. It uses no RAM while stopped. Disk usage is approximately 309 MB for the SDK, 16 MB for device support and fonts, and 932 MB for the simulator image, about 1.26 GB total.
