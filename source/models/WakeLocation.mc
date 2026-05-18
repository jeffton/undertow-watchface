import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Position;

class WakeLocation {
  static function fromStoredWeather() as Position.Location? {
    var data = Storage.getValue("weather") as Dictionary?;
    if (data == null) {
      return null;
    }

    return fromWeatherData(data);
  }

  static function fromWeatherData(data as Dictionary) as Position.Location {
    var requestPosition = data.get("requestPosition") as [Double, Double];
    return new Position.Location({
      :latitude => requestPosition[0],
      :longitude => requestPosition[1],
      :format => :degrees
    });
  }
}
