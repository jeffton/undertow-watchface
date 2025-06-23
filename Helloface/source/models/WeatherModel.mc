import Toybox.Weather;
import Toybox.Lang;

class WeatherModel {

  var temperature as String = "-";
  var windSpeed as String = "-";
  var windBearing as Number?;
  var condition as Number?;
  var isDaytime as Boolean;

  function initialize(isDaytime as Boolean) {
    self.isDaytime = isDaytime;

    var currentWeather = Weather.getCurrentConditions();
    if (currentWeather == null) {
      return;
    }

    self.temperature = Math.round(currentWeather.temperature).format("%i") + "°";
    if (currentWeather.windSpeed != null) {
      self.windSpeed = Math.round(currentWeather.windSpeed).format("%i");
    }
    self.windBearing = currentWeather.windBearing;
    self.condition = currentWeather.condition;
  }
}