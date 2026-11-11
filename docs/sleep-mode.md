# Sleep mode

The face uses [`ActivityMonitor.Info.isSleepMode`](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityMonitor/Info.html#isSleepMode-var) for both night rendering and Wake sync. This is device sleep mode, not physiological sleep detection. Garmin marks the field deprecated and nullable; the Instinct 2 simulator exposes it, but physical firmware behavior remains unverified.

- `true`: night display and `awake=0` at sync.
- `false`: day display and `awake=1` at sync.
- Missing/null: day display, with the optional `awake` field omitted. No sleep status is inferred from time, gestures or Do Not Disturb.

Night mode shows hours/minutes, the current alarm-enabled icon, the existing sun-position graphic, and Body Battery as a number and ring. Missing Body Battery is shown as `-`. It reuses existing bitmaps and skips partial-update model creation/drawing. Full model refreshes and the existing sync cadence are unchanged. Mode/alarm changes are visible at the next full update (up to one minute in low-power mode).

[`WatchFace.onEnterSleep`](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/WatchFace.html#onEnterSleep-instance_function) only indicates low-power rendering and is not used as the user's sleep status.

## Validation — 11 November 2026

SDK 9.3.0, Instinct 2 simulator (API 3.4.2), release models/builds, isolated Ubuntu simulator container. Baseline: `a90f32c`. No watch or Wake-service deployment.

| Measurement | Baseline | Sleep-mode branch |
| --- | ---: | ---: |
| Release PRG, empty Wake template | 32,892 B | 33,484 B |
| Foreground compiled code + data | 22,140 B | 22,740 B |
| Background compiled code + data | 2,696 B | 2,867 B |
| Sampled day RAM after initialization | 38,480 B | 39,152 B |
| Initial post-render day RAM sample | 38,632 B | 39,304 B |
| Median day full-update time | 1 ms | 1 ms |
| Median night full-update time | — | 1 ms |

The baseline run recorded 51 full updates; the branch recorded 33 day and 66 night updates. Maximum sampled full-update times were 6 ms baseline, 5 ms branch/day and 2 ms branch/night.

RAM samples use identical release-model fixtures: one compact weather forecast at 55.6°N/13.0°E, one enabled alarm and simulator health values. Temporary copies of both revisions log `System.getSystemStats().usedMemory/freeMemory` immediately after `onUpdate`, timed with `System.getTimer()`. Fixtures and logging are not included in shipped code. The matched steady-state increase is **672 B**; about **22 kB** remains free in these runs. Repeated day/night switches retain loaded day bitmaps rather than allocating another screen buffer.

These are simulator samples, not heap-peak or battery-life guarantees. Real forecast size, health history, firmware and model-update transients affect headroom. The simulator's memory window reported a 40.5 kB peak in an instrumented day run. Its runtime budget was about 59.8 kB; the compiler's printed 96 kB foreground percentage does not represent the watchface heap limit (the device file specifies 64 KiB).

Verified:

- Simulator Settings → Sleep Mode switches day → night → day using release models; time advances across minute boundaries.
- Alarm icon responds to the simulator alarm count. Body Battery is formatted as an integer even when simulator history returns a floating-point sample.
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
