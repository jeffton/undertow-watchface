import Toybox.Time;
import Toybox.Lang;
import Toybox.Application.Storage;

class WeatherRepository {
  var weatherData as Dictionary?;
  const FORECAST_IDX_TIME = 0;
  const FORECAST_IDX_SEA_TEMPERATURE = 1;
  const FORECAST_IDX_WAVE_HEIGHT = 2;
  const FORECAST_IDX_WAVE_DIRECTION = 3;
  const FORECAST_IDX_TEMPERATURE = 4;
  const FORECAST_IDX_WIND_SPEED = 5;
  const FORECAST_IDX_WIND_DIRECTION = 6;
  const FORECAST_IDX_CLOUD_COVER = 7;
  const FORECAST_IDX_CONDITION = 8;
  const FORECAST_IDX_UV_INDEX = 9;
  const FORECAST_IDX_PRECIPITATION = 10;

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

    var cloudCover = getForecastValue(forecast, FORECAST_IDX_CLOUD_COVER);
    if (cloudCover instanceof Array) {
      var size = cloudCover.size();
      if (size >= 1) {
        model.cloudCover = cloudCover[0] as Numeric?;
      }
      if (size >= 4) {
        model.cloudCoverLow = cloudCover[1] as Numeric?;
        model.cloudCoverMedium = cloudCover[2] as Numeric?;
        model.cloudCoverHigh = cloudCover[3] as Numeric?;
      }
    }

    model.precipitation = getForecastValue(forecast, FORECAST_IDX_PRECIPITATION) as Numeric?;
    var uvIndex = getForecastValue(forecast, FORECAST_IDX_UV_INDEX) as Number?;
    if (uvIndex != null) {
      model.uvIndex = Math.round(uvIndex).format("%i");
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
