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

    var waveHeight = forecast.get("waveHeight");
    if (waveHeight != null) {
      model.waveHeight = (waveHeight as Float).format("%.1f") + "m";
    }

    model.waveDirection = forecast.get("waveDirection") as Numeric?;
    model.windDirection = forecast.get("windDirection") as Numeric?;
    model.condition = forecast.get("condition") as String?;

    var cloudCover = forecast.get("cloudCover");
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

    model.precipitation = forecast.get("precipitation") as Numeric?;
    var uvIndex = forecast.get("uvIndex") as Number?;
    if (uvIndex != null) {
      model.uvIndex = Math.round(uvIndex).format("%i");
    }

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
      }
    }
    return null;
  }
}
