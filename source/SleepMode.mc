import Toybox.ActivityMonitor;
import Toybox.Lang;

(:background)
module SleepMode {
  function read() as Boolean? {
    var info = ActivityMonitor.getInfo();
    if (info has :isSleepMode) {
      return info.isSleepMode;
    }
    return null;
  }
}
