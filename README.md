# Undertow

A feature-rich Garmin watchface for Instinct 2, designed for outdoor enthusiasts who want comprehensive data at a glance.

![Undertow Watchface](resources/drawables/LauncherIcon.png)

## Features

### Time & Date
- Large, easy-to-read digital time display
- Live seconds with partial screen updates for battery efficiency
- Day and date display

### Weather
- Current temperature with weather condition icons
- Wind speed and direction indicator (animated compass arrow)
- UV index (shown when > 0)
- Precipitation warning (umbrella icon when ≥80% chance)
- Sunrise/sunset times

### Ocean Data (via Wake Service)
- Sea water temperature 🌊
- Wave height and direction
- Automatically shown when near the coast, falls back to altitude when inland

### Activity Tracking
- Step count with goal progress ring
- Weekly active minutes bar with daily progress indicator
- Workout indicator when activity recorded today
- Recovery time bar (scales from 24h to 96h based on fatigue)

### Health Metrics
- Real-time heart rate with colored heart icon based on stress level:
  - 🤍 Resting (0-25)
  - 💛 Low stress (26-50)
  - 🧡 Medium stress (51-75)
  - ❤️ High stress (76+)
- Body Battery as circular progress around heart display
- Stress level visualization

### Environmental
- Barometric pressure gauge (needle indicates high/low pressure)
- Altitude display (when not showing sea temperature)
- Sun position arc showing current position between sunrise and sunset

### Device Status
- Battery level indicator
- Notification count with phone connection status
- Do Not Disturb indicator
- Alarm indicator

### Background Sync
Syncs with [Wake Service](https://github.com/jeffton/wake-service) for:
- Extended weather data including ocean conditions
- GPS location logging
- Workout notifications to trigger AI assistant feedback

## Setup

### Wake Service Configuration

1. Copy the template file:
   ```bash
   cp source/background/WakeServiceSettings.mc.template source/background/WakeServiceSettings.mc
   ```

2. Edit `WakeServiceSettings.mc` with your values:
   ```monkey-c
   module WakeServiceSettings {
     const URL = "https://your-wake-service.example.com/weather";
     const API_KEY = "your-api-key-here";
   }
   ```

3. The real `WakeServiceSettings.mc` is gitignored to keep credentials private.

### Building

Requires [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/).

```bash
# Build for Instinct 2
monkeyc -d instinct2 -f monkey.jungle -o undertow.prg
```

## Permissions

- **Background** - Periodic weather updates
- **Communications** - Fetch data from Wake Service
- **Positioning** - GPS for weather location
- **SensorHistory** - Body battery and stress data
- **UserProfile** - User settings

## Compatibility

Currently built for:
- Garmin Instinct 2 (176x176 display)

## Architecture

```
source/
├── UndertowApp.mc          # Application entry point
├── UndertowView.mc         # Main watchface rendering
├── models/
│   ├── SecondModel.mc      # Per-second updates (time, HR, notifications)
│   ├── MinuteModel.mc      # Per-minute updates (battery, steps, body battery)
│   ├── TenMinuteModel.mc   # Sun calculations
│   ├── DayModel.mc         # Date, alarm, workout status
│   ├── WeatherModel.mc     # Weather display data
│   └── SunModel.mc         # Sun position calculations
├── background/
│   ├── WakeSyncService.mc  # Background data sync
│   └── ActivityCountService.mc  # Workout tracking
└── resources/              # Icons and drawables
```

## License

MIT
