import Toybox.Time;
import Toybox.Lang;
import Toybox.Application.Storage;
import Toybox.Time.Gregorian;
import Toybox.Weather;

class WeatherRepository {
  var weatherData as Dictionary?;

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

    var seaTemp = forecast.get("seaTemperature");
    if (seaTemp != null) {
      model.seaTemperature = (seaTemp as Float).format("%.1f") + "°";
    }

    var temp = forecast.get("temperature");
    if (temp != null) {
      model.temperature = Math.round(temp as Float).format("%i") + "°";
    }

    var wSpeed = forecast.get("windSpeed");
    if (wSpeed != null) {
      model.windSpeed = Math.round(wSpeed as Float).format("%i");
    }

    model.windDirection = forecast.get("windDirection") as Number?;

    var conditionString = forecast.get("condition") as String?;
    model.condition = conditionStringToEnum(conditionString);

    return model;
  }
 
  private function findNextForecast() as Dictionary? {
    if (self.weatherData != null && self.weatherData.hasKey("forecast")) {
      var hours = self.weatherData.get("forecast");
      if (hours instanceof Array && hours.size() > 0) {
        var now = Time.now().value();
        for (var i = 0; i < hours.size(); i++) {
          var time = hours[i].get("time");
          if (now <= time) {
            return hours[i];
          }
        }
        // if we are past the last forecast, just use the last one
        return hours[hours.size() - 1];
      }
    }
    return null;
  }

  private function conditionStringToEnum(condition as String?) as Number? {
    if (condition == null) {
      return null;
    }
    switch (condition) {
      case "clear":
        return Weather.CONDITION_CLEAR;
      case "partly cloudy":
        return Weather.CONDITION_PARTLY_CLOUDY;
      case "cloudy":
        return Weather.CONDITION_CLOUDY;
      case "light rain":
        return Weather.CONDITION_LIGHT_RAIN;
      case "rain":
        return Weather.CONDITION_RAIN;
      case "thunder":
        return Weather.CONDITION_THUNDERSTORMS;
      case "snow":
        return Weather.CONDITION_SNOW;
      case "hail":
        return Weather.CONDITION_HAIL;
      case "fog":
        return Weather.CONDITION_FOG;
      default:
        return Weather.CONDITION_UNKNOWN;
    }
  }
} 