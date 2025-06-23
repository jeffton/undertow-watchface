import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

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

}