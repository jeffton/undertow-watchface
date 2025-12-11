import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Math;

class Utils {

  static function formatTimeMoment(time as Moment?) as String {
    if (time == null) { 
      return "-:--";
    } 
    var timeInfo = Gregorian.info(time, Time.FORMAT_SHORT);
    return formatTime(timeInfo.hour, timeInfo.min);
  }

  static function formatTime(hour as Number, minute as Number) as String {
    return Lang.format("$1$:$2$", [
      hour,
      minute.format("%02d"),
    ]);
  }

  static function scaleValue(value as Numeric, oldScale as Numeric, newScale as Number) {
    return Math.round(value.toFloat() * newScale / oldScale).toNumber();
  }

  static function getPointAtAngle(centerX as Number, centerY as Number, radius as Number, angle as Float or Number) as Array<Numeric> {
    var radians = Math.toRadians(angle);
    var x = centerX + radius * Math.sin(radians);
    var y = centerY - radius * Math.cos(radians);
    return [Math.round(x), Math.round(y)];
  }

}
