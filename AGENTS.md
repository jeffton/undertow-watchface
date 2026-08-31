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
