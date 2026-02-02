# Undertow

Garmin watchface for Instinct 2 with weather, ocean data and activity tracking.

## Features

### Time & Date
- Digital time with live seconds (partial screen updates)
- Day and date

### Weather & Ocean Data
Fetched from [Wake Service](https://github.com/jeffton/wake-service):
- Temperature and weather icons
- Wind speed and animated compass arrow
- UV index (shown when > 0)
- Precipitation warning (umbrella icon at ≥80% chance)
- Sunrise/sunset times
- Sea water temperature 🌊 (near coast, otherwise shows altitude)
- Wave height and direction

### Activity Tracking
- Step count with goal progress ring
- Weekly active minutes bar with daily progress
- Workout indicator when activity recorded today
- Recovery time bar (scales from 24h to 96h)

### Health Metrics
- Real-time heart rate
- Body Battery (circular progress)
- Stress level

### Environmental
- Barometric pressure gauge (needle indicates high/low)
- Altitude (when not showing sea temperature)
- Sun position arc between sunrise and sunset

### Device Status
- Battery level
- Notification count and phone connection status
- Do Not Disturb / Alarm indicators

### Background Sync
Syncs with Wake Service for:
- Weather and ocean data
- GPS location logging
- Workout notifications to AI assistant

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

## Permissions

- **Background** - Periodic weather updates
- **Communications** - Fetch data from Wake Service
- **Positioning** - GPS for weather location
- **SensorHistory** - Body battery and stress data
- **UserProfile** - User settings

## Compatibility

- Garmin Instinct 2 (176x176 display)

## License

MIT
