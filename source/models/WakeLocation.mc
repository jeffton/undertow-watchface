import Toybox.Lang;
import Toybox.Position;

class WakeLocation {
  static function fromWeatherData(data as Dictionary?) as Position.Location? {
    if (data == null) {
      return null;
    }

    var requestPosition = data.get("requestPosition") as [Double, Double];
    return new Position.Location({
      :latitude => requestPosition[0],
      :longitude => requestPosition[1],
      :format => :degrees
    });
  }
}
