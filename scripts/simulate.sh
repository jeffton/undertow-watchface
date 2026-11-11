#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
CIQ="$HOME/.Garmin/ConnectIQ"
SDK=$(<"$CIQ/current-sdk.cfg")
OUTPUT=${1:-$(mktemp -d /tmp/undertow-simulator.XXXXXX)}
mkdir -p "$OUTPUT" bin
OUTPUT=$(realpath "$OUTPUT")
NAME="undertow-simulator-$$"

"$SDK/bin/monkeyc" -o bin/Undertow.prg -f monkey.jungle \
    -y "$CIQ/Keys/developer_key.der" -d instinct2_sim -l 1 -w

podman --cgroup-manager=cgroupfs run -d --rm --network none --name "$NAME" \
    -e SDK="/root/.Garmin/ConnectIQ/Sdks/$(basename "$SDK")" \
    -v "$CIQ/Sdks:/root/.Garmin/ConnectIQ/Sdks:ro" \
    -v "$CIQ/Devices:/root/.Garmin/ConnectIQ/Devices:ro" \
    -v "$CIQ/Fonts:/root/.Garmin/ConnectIQ/Fonts:ro" \
    -v "$PWD/bin:/app/bin:ro" -v "$OUTPUT:/out" \
    localhost/garmin-connectiq-sim:22.04 bash -lc '
        export DISPLAY=:99
        trap '\''kill $(jobs -pr); exit'\'' TERM INT
        Xvfb :99 -screen 0 1280x1024x24 -nolisten tcp >/out/xvfb.log 2>&1 &
        openbox >/out/openbox.log 2>&1 &
        "$SDK/bin/simulator" >/out/simulator.log 2>&1 &
        sleep infinity &
        wait
    ' >/dev/null
trap 'podman --cgroup-manager=cgroupfs stop "$NAME" >/dev/null' EXIT

podman --cgroup-manager=cgroupfs exec "$NAME" bash -lc '
    set -euo pipefail
    export DISPLAY=:99
    timeout 30 bash -c '\''until xdotool search --name "CIQ Simulator" >/dev/null; do sleep 0.2; done'\''
    "$SDK/bin/monkeydo" /app/bin/Undertow.prg instinct2 >/out/monkeydo.log 2>&1 &
    timeout 30 bash -c '\''
        until xdotool search --name "CIQ Simulator" getwindowgeometry --shell | grep -q "^HEIGHT=554$"; do
            sleep 0.2
        done
    '\''
    WINDOW=$(xdotool search --name "CIQ Simulator" | head -1)
    import -display :99 -window "$WINDOW" /out/simulator-window.png
    convert /out/simulator-window.png -crop 176x176+100+190 +repage /out/watch-screen.png
'
test -s "$OUTPUT/simulator-window.png"
test -s "$OUTPUT/watch-screen.png"
printf 'Screenshots: %s\n' "$OUTPUT"
