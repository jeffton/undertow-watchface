# Undertow

Garmin watchface for Instinct 2 with weather, ocean data and activity tracking.

<p align="center">
  <img src="screenshot.png" alt="Undertow watchface screenshot" style="width: 100%; max-width: 640px; height: auto;" />
</p>

## Features

### The basics
- Partial updates every second for seconds, heart rate & notifications
- Battery-optimized updates of everything

### Weather
- Weather & ocean data provided by [YR](https://www.yr.no/) via [Wake Service](https://github.com/jeffton/wake-service)
- Ocean data falls back to altidude display when far from the ocean

### OpenClaw integration
- Can ping your [OpenClaw](https://openclaw.ai) bot via [Wake Service](https://github.com/jeffton/wake-service) once you save an activity, so that your bot can check stats on Garmin Connect and give feedback.

## Settings

### Wake Service Configuration

1. Copy the template file:
   ```bash
   cp source/background/WakeServiceSettings.mc.template source/background/WakeServiceSettings.mc
   ```

2. Edit `WakeServiceSettings.mc` with your values:
   ```monkey-c
   module WakeServiceSettings {
     const URL = "https://your-wake-service.example.com/sync";
     const API_KEY = "your-api-key-here";
   }
   ```

3. The real `WakeServiceSettings.mc` is in .gitignore


## Compatibility

- Built for Garmin Instinct 2 (176x176 display). Should be trivial to add support for other Instinct models with the same resolution. Other Garmin watches would require reworking the view as everything is drawn in black and white at fixed coordinates.

### AI usage
- Most of this watchface is hand-coded (made it before the recent AI explosion)
- Later features have been prompted with Codex & carefully reviewed

## License

MIT
