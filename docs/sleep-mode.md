# Sleep mode

The face uses [`ActivityMonitor.Info.isSleepMode`](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityMonitor/Info.html#isSleepMode-var) for both night rendering and Wake sync. This deprecated, nullable SDK flag is a candidate signal: the simulator exposes it, but its connection to modern Sleep Mode on physical Instinct 2 firmware is unverified. It is not physiological sleep detection.

- `true`: night display and `awake=0` at sync.
- `false`: day display and `awake=1` at sync.
- Missing/null: day display, with the optional `awake` field omitted. No sleep status is inferred from time, gestures or Do Not Disturb.

Night mode shows hours/minutes centered on the dial, the alarm-enabled icon centered in the space to the right of the time, the sun-position graphic centered in the space below the time, and the Body Battery ring without a number. Missing Body Battery leaves the ring absent. It reuses existing bitmaps and skips partial-update model creation/drawing. Full model refreshes and the existing sync cadence are unchanged. Mode/alarm changes are visible at the next full update (up to one minute in low-power mode).

[`WatchFace.onEnterSleep`](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/WatchFace.html#onEnterSleep-instance_function) only indicates low-power rendering and is not used as the user's sleep status.

## Validation — 11 November 2026

SDK 9.3.0, Instinct 2 simulator (API 3.4.2), release models/builds, isolated Ubuntu simulator container. No physical watch validation, watch installation or Wake-service deployment.

Layout resource comparison against `86eb0ea`:

| Measurement | `86eb0ea` | Layout branch |
| --- | ---: | ---: |
| Release PRG, empty Wake template | 33,452 B | 33,564 B |
| Foreground compiled code + data | 22,705 B | 22,816 B |
| Background compiled code + data | 2,867 B | 2,867 B |
| First post-render RAM sample, night start | 37,448 B | 37,560 B |
| Median night full-update time | 1 ms | 1 ms |

Matched cold-start samples use release models, one compact weather forecast at 55.6°N/13.0°E, one enabled alarm and simulator health values. Temporary copies log `System.getSystemStats().usedMemory/freeMemory` immediately after `onUpdate`, timed with `System.getTimer()`. Fixtures and logging are not included in shipped code. The layout adds no bitmap or persistent state; the first night RAM sample increases by **112 B**, with about **24 kB free**. Both timing runs have a 1 ms median. Text dimensions require a small temporary allocation per full night redraw.

These are simulator samples, not heap-peak or battery-life guarantees. Real forecast size, health history, firmware and model-update transients affect headroom. Day/night transitions were exercised; loaded day bitmaps are retained rather than allocating another screen buffer. The simulator runtime budget is about 59.8 kB; the compiler's printed 96 kB foreground percentage does not represent the watchface heap limit (the device file specifies 64 KiB).

Verified:

- Simulator Settings → Sleep Mode switches day → night → day using release models; time advances across minute boundaries.
- Night layouts at `6:05`, `10:10`, `11:11` and `23:59` have no time/alarm/sun overlap. Positioning uses SDK text dimensions and the alarm bitmap dimensions: the alarm is vertically centered on the time and horizontally centered in the remaining right-hand space; the sun is horizontally centered on the dial and vertically centered in the remaining space below the time. Daytime rendering is unchanged.
- Real background temporal callbacks construct `awake=0` and `awake=1` with the simulator flag enabled/disabled. A temporary transport interception records the body and exits before the web request; no requests reach Wake.
- The Monkey C unit test checks compact-format payloads, workout preservation and true/false/unknown sleep states.
- Debug, release and test builds succeed with the expected deprecated-API warning.

To run the unit test with a running simulator:

```bash
monkeyc -t -o bin/Undertow-test.prg -f monkey.jungle \
  -y "$HOME/.Garmin/ConnectIQ/Keys/developer_key.der" \
  -d instinct2_sim -l 1 -w
monkeydo bin/Undertow-test.prg instinct2 -t
```
