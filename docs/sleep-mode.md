# Sleep mode

The face uses [`ActivityMonitor.Info.isSleepMode`](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityMonitor/Info.html#isSleepMode-var) for both night rendering and Wake sync. This deprecated, nullable SDK flag is a candidate signal: the simulator exposes it, but its connection to modern Sleep Mode on physical Instinct 2 firmware is unverified. It is not physiological sleep detection.

- `true`: night display and `awake=0` at sync.
- `false`: day display and `awake=1` at sync.
- Missing/null: day display, with the optional `awake` field omitted. No sleep status is inferred from time, gestures or Do Not Disturb.

Night mode shows hours/minutes centered on the dial, the alarm-enabled icon centered in the space to the right of the time, the sun-position graphic centered in the space below the time, and the Body Battery ring without a number. Missing Body Battery leaves the ring absent. It reuses existing bitmaps and skips partial-update model creation/drawing. Full model refreshes and the existing sync cadence are unchanged. Mode/alarm changes are visible at the next full update (up to one minute in low-power mode).

[`WatchFace.onEnterSleep`](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/WatchFace.html#onEnterSleep-instance_function) only indicates low-power rendering and is not used as the user's sleep status.

## Font geometry

Calibration uses rendered `FONT_NUMBER_THAI_HOT` glyph pixels on the Instinct 2 simulator with SDK 9.3.0. Digits advance 22 px; the colon advances 10 px. The line height is 56 px, but every digit ends at relative row 48 inclusive, leaving **7 blank bottom rows**. The sun uses the visible bottom edge and sits at y=145 rather than the line-box midpoint y=148.

| Digit | Left blank columns | Right blank columns |
| --- | ---: | ---: |
| 0, 6, 9 | 2 | 2 |
| 1 | 6 | 5 |
| 2 | 3 | 1 |
| 3, 5, 7 | 3 | 2 |
| 4 | 2 | 0 |
| 8 | 2 | 1 |

Horizontal placement uses the first and last digit's insets rather than centering the advance box. In the original centered rendering, `10:10` had visible x-bounds 45–134 and an ink center **2 px right** of the dial center. Its corrected bounds are 43–132. `6:05` needed no horizontal shift; `11:11` and `23:59` are left unchanged because their half-pixel difference cannot be improved on the pixel grid. Seven rendered time samples and calculations over all 1,440 minute values place the ink center within half a pixel of the dial center. Alarm coordinates and Body Battery rendering are unchanged.

## Validation — 11 November 2026

SDK 9.3.0, Instinct 2 simulator (API 3.4.2), release models/builds, isolated Ubuntu simulator container. No physical watch validation, watch installation or Wake-service deployment.

Layout resource comparison against `e018738`:

| Measurement | `e018738` | Layout branch |
| --- | ---: | ---: |
| Release PRG, empty Wake template | 33,564 B | 33,836 B |
| Foreground compiled code + data | 22,816 B | 23,086 B |
| Background compiled code + data | 2,867 B | 2,867 B |
| First post-render RAM sample, night start | 37,552 B | 37,824 B |
| Median night full-update time | 1 ms | 1 ms |

Matched cold-start samples use release models, one compact weather forecast at 55.6°N/13.0°E, one enabled alarm and simulator health values. Temporary copies log `System.getSystemStats().usedMemory/freeMemory` immediately after `onUpdate`, timed with `System.getTimer()`. Fixtures and logging are not included in shipped code. The correction adds no bitmap, lookup array or mutable persistent state. The first night RAM sample increases by **272 B**, with **23.4 kB free**. Both timing runs have a 1 ms median.

These are simulator samples, not heap-peak or battery-life guarantees. Real forecast size, health history, firmware and model-update transients affect headroom. Day/night transitions were exercised; loaded day bitmaps are retained rather than allocating another screen buffer. The simulator runtime budget is about 59.8 kB; the compiler's printed 96 kB foreground percentage does not represent the watchface heap limit (the device file specifies 64 KiB).

Verified:

- Simulator Settings → Sleep Mode switches day → night → day using release models; time advances across minute boundaries.
- Rendered night layouts at `0:00`, `6:05`, `10:10`, `11:11`, `12:24`, `20:21` and `23:59` have no time/alarm/sun overlap. Pixel bounds confirm the horizontal font correction and the sun's 3 px upward shift. The alarm retains its SDK line-box positioning; daytime rendering is unchanged.
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
