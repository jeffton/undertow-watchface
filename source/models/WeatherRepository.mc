import Toybox.Time;
import Toybox.Lang;
import Toybox.Application.Storage;

class WeatherRepository {
  var weatherData as Dictionary?;
  const FORECAST_IDX_TIME as Number = 0;
  const FORECAST_IDX_SEA_TEMPERATURE as Number = 1;
  const FORECAST_IDX_WAVE_HEIGHT as Number = 2;
  const FORECAST_IDX_WAVE_DIRECTION as Number = 3;
  const FORECAST_IDX_TEMPERATURE as Number = 4;
  const FORECAST_IDX_WIND_SPEED as Number = 5;
  const FORECAST_IDX_WIND_DIRECTION as Number = 6;
  const FORECAST_IDX_CONDITION as Number = 7;
  const FORECAST_IDX_UV_INDEX as Number = 8;
  const FORECAST_IDX_PRECIPITATION as Number = 9;

  function initialize() {
    self.weatherData = Storage.getValue("weather") as Dictionary?;
  }

  function update() {
    new WeatherService().update(self.weatherData);
  }

  function onWeatherUpdated(data as Dictionary) {
    self.weatherData = data;
  }

  function getWeatherModel() as WeatherModel {
    var model = new WeatherModel();
    var forecast = findNextForecast();
    if (forecast == null) {
      return model;
    }

    var seaTemp = getForecastValue(forecast, FORECAST_IDX_SEA_TEMPERATURE);
    if (seaTemp != null) {
      if (seaTemp < 9.95) {
        // 1 decimal:
        model.seaTemperature = (seaTemp as Float).format("%.1f") + "°";
      } else {
        // 0 decimals:
        model.seaTemperature = Math.round(seaTemp as Float).format("%i") + "°";
      }
    }

    var temp = getForecastValue(forecast, FORECAST_IDX_TEMPERATURE);
    if (temp != null) {
      model.temperature = Math.round(temp as Float).format("%i") + "°";
    }

    var wSpeed = getForecastValue(forecast, FORECAST_IDX_WIND_SPEED);
    if (wSpeed != null) {
      model.windSpeed = Math.round(wSpeed as Float).format("%i");
    }

    var waveHeight = getForecastValue(forecast, FORECAST_IDX_WAVE_HEIGHT);
    if (waveHeight != null) {
      model.waveHeight = (waveHeight as Float).format("%.1f");
    }

    model.waveDirection = getForecastValue(forecast, FORECAST_IDX_WAVE_DIRECTION) as Numeric?;
    model.windDirection = getForecastValue(forecast, FORECAST_IDX_WIND_DIRECTION) as Numeric?;
    model.condition = getForecastValue(forecast, FORECAST_IDX_CONDITION) as String?;

    model.precipitation = getForecastValue(forecast, FORECAST_IDX_PRECIPITATION) as Numeric?;
    var uvIndex = getForecastValue(forecast, FORECAST_IDX_UV_INDEX) as Number?;
    if (uvIndex != null) {
      model.uvIndex = Math.round(uvIndex).toNumber();
    }

    return model;
  }
 
  private function findNextForecast() as Array? {
    if (self.weatherData != null && self.weatherData.hasKey("forecast")) {
      var hours = self.weatherData.get("forecast");
      if (hours instanceof Array && hours.size() > 0) {
        var now = Time.now().value();
        for (var i = 0; i < hours.size(); i++) {
          var entry = hours[i];
          if (entry instanceof Array && entry.size() > FORECAST_IDX_TIME) {
            var time = entry[FORECAST_IDX_TIME];
            if (time instanceof Number && now <= time) {
              return entry;
            }
          }
        }
      }
    }
    return null;
  }

  private function getForecastValue(forecast as Array?, idx as Number) {
    if (forecast != null && forecast.size() > idx) {
      return forecast[idx];
    }
    return null;
  }
}
