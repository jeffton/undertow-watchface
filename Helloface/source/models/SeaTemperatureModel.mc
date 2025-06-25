import Toybox.Time;
import Toybox.Lang;
import Toybox.Application.Storage;
import Toybox.Time.Gregorian;

class SeaTemperatureModel {
  var seaData as Dictionary?;
  var seaTemperature as String?;

  function initialize() {
    self.seaData = Storage.getValue("sea-data") as Dictionary?;
    self.seaTemperature = getSeaTemperature();
  }

  function update() {
    new SeaTemperatureService().update(self.seaData);
  }

  function onSeaDataUpdated(data as Dictionary) {
    self.seaData = data;
    self.seaTemperature = getSeaTemperature();
  }
 
  function getSeaTemperature() as String? {
    var temperature = getSeaTemperatureFromStorage();
    return formatTemperature(temperature);
  }

  function getSeaTemperatureFromStorage() as Float? {
    if (self.seaData != null && self.seaData.hasKey("forecast")) {
      var hours = self.seaData.get("forecast");
      if (hours instanceof Array) {
        return findNextTemperature(hours);
      }
    }
    return null;
  }

  function findNextTemperature(hours as Array) as Float? {
    var now = Time.now().value();
    for (var i = 0; i < hours.size(); i++) {
      var time = hours[i].get("time");
      if (now <= time) {
        return hours[i].get("seaTemperature");
      }
    }
    return null;
  }

  function formatTemperature(temperature as Numeric?) as String? {
    if (temperature == null) {
      return null;
    }

    return temperature.format("%.1f") + "°";
  }
}