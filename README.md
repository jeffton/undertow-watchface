# Undertow

Garmin watchface for Instinct 2 med vejr, havdata og aktivitetssporing.

## Features

### Time & Date
- Digital tid med live sekunder (partial screen updates)
- Dag og dato

### Weather & Ocean Data
Data hentes fra [Wake Service](https://github.com/jeffton/wake-service):
- Temperatur og vejrikoner
- Vind (hastighed + animeret kompaspil)
- UV-index (vises når > 0)
- Nedbørsvarsel (paraply-ikon ved ≥80% chance)
- Solopgang/solnedgang
- Havtemperatur 🌊 (nær kysten, ellers vises højde)
- Bølgehøjde og -retning

### Activity Tracking
- Skridt med goal progress ring
- Ugentlige aktive minutter (bar med daglig progress)
- Workout-indikator når aktivitet registreret i dag
- Recovery time bar (skalerer fra 24h til 96h)

### Health Metrics
- Real-time puls
- Body Battery (cirkulær progress)
- Stress level

### Environmental
- Barometrisk tryk (nål viser høj/lav)
- Højde (når havtemperatur ikke vises)
- Sol-arc med aktuel position mellem solopgang/solnedgang

### Device Status
- Batteriniveau
- Notifikationstæller + telefonforbindelse
- Do Not Disturb / Alarm indikatorer

### Background Sync
Synkroniserer med Wake Service:
- Vejr og havdata
- GPS-lokationslog
- Workout-notifikationer til AI-assistent

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
