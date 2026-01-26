import Toybox.Lang;
import Toybox.Time;
import Toybox.System;

class UpdateTime {

  enum Diff {
    EQUAL,
    SECOND,
    MINUTE,
    TEN_MINUTES,
    DAY
  }

  var clockTime as ClockTime;
  var today as Moment;

  function initialize() {
    self.clockTime = System.getClockTime();
    self.today = Time.today();
  }

  // Safely assumes that previous is at most one minute ago (otherwise the watch face would have restarted)
  function compare(previous as UpdateTime) as Diff {
    if (previous.today.compare(self.today) != 0) {
      return DAY;
    } 
    
    if (previous.clockTime.min != self.clockTime.min) {
      if (self.clockTime.min % 10 == 0) {
        return TEN_MINUTES; // not actually ten minutes since last, but we return this once every ten minutes
      } else {
        return MINUTE;
      }
    } 
    if (previous.clockTime.sec != self.clockTime.sec) {
      return SECOND;
    }

    return EQUAL;
  }

  function compareSeconds(previous as UpdateTime) as Diff {
    if (previous.clockTime.sec != self.clockTime.sec) {
      return SECOND;
    }

    return EQUAL;
  }
}