Skip comments.

Use typing for everything the compiler permits. Monkey C 3.4 rejects explicit typing of local variables, so let local variable types be inferred.

## Linux build environment

The Arch server uses Connect IQ SDK 9.3.0 (20 October 2026), Instinct 2 device support and fonts under `~/.Garmin/ConnectIQ/`. The signing key is `~/.Garmin/ConnectIQ/Keys/developer_key.der`. `monkeyc` and `monkeydo` wrappers in `/usr/local/bin/` follow `current-sdk.cfg`.

`connect-iq-sdk-manager` 0.8.4 is installed in `~/.local/bin/`. Check Garmin's [SDK page](https://developer.garmin.com/connect-iq/sdk/) and the installed SDK's `doc/docs/Readme/History.html` before upgrading:

```bash
connect-iq-sdk-manager sdk list
connect-iq-sdk-manager sdk set <latest-stable-version>
connect-iq-sdk-manager device download --manifest=manifest.xml --include-fonts
```

The existing SDK login token is stored locally. If reauthentication is required, load the existing Garmin credentials into the manager's `GARMIN_USERNAME`/`GARMIN_PASSWORD` environment variables without printing them or passing them as command-line arguments.

## Configuration

`source/background/WakeServiceSettings.mc` is ignored by Git. For compile-only/demo work, copy the empty template if the generated file is missing:

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
monkeyc -o bin/Undertow.prg -f monkey.jungle \
  -y "$HOME/.Garmin/ConnectIQ/Keys/developer_key.der" \
  -d instinct2_sim -l 1 -w
```

For a sideloadable release, use the real Wake configuration and add `-r`, writing to `dist/Undertow.prg`. `bin/`, `dist/` and the generated Wake settings must remain uncommitted.

## Simulator and screenshots

The simulator requires legacy GTK/WebKit libraries absent on the host. Podman runs it with Xvfb in an Ubuntu 22.04 image; no host ports or network are exposed. Build the image once:

```bash
podman --cgroup-manager=cgroupfs build \
  -t localhost/garmin-connectiq-sim:22.04 -f scripts/Containerfile scripts
```

Run from any directory:

```bash
bash /home/roy/github/undertow-watchface/scripts/simulate.sh
```

The script builds with the selected SDK, starts an isolated simulator, captures `simulator-window.png` and a native 176×176 `watch-screen.png`, then stops/removes its container. It prints the output directory; an optional argument selects another directory. Logs remain beside the screenshots. Debug builds use `DemoModelsRepository`, so screenshots contain demo values rather than live health data. The script's window geometry and screen crop are specific to Instinct 2.

Device fonts and their existing Bitstream aliases are preserved in `~/.Garmin/ConnectIQ/Fonts/`. If setting up from scratch and Garmin's API rejects the three generic filenames containing spaces, install aliases from the corresponding Garmin fonts:

```bash
F="$HOME/.Garmin/ConnectIQ/Fonts"
cp "$F/FNT_006B388800_0000_GARMIN_16.cft" "$F/bitstreamVeraSans 16.cft"
cp "$F/FNT_006B388800_0000_GARMIN_20.cft" "$F/bitstreamVeraSans 21.cft"
cp "$F/FNT_006B388800_0000_GARMIN_30.cft" "$F/bitstreamVeraSans 27.cft"
```
