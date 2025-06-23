import Toybox.Lang;
import Toybox.System;
import Toybox.Activity;

class SecondModel {

  enum Diff {
    UPDATE_DIFF_SECONDS,
    UPDATE_DIFF_SECONDS_AND_PULSE,
    UPDATE_DIFF_ALL
  }

  var clockTime as ClockTime;

  var seconds as String;
  var heartRate as Number or String;
  var notificationCount as Number;
  var isPhoneConnected as Boolean;
  var doNotDisturb as Boolean;

  function initialize(updateTime as UpdateTime) {
    self.clockTime = updateTime.clockTime;
    var deviceSettings = System.getDeviceSettings();
    var activityInfo = Activity.getActivityInfo();

    self.seconds = clockTime.sec.format("%02d");
    self.isPhoneConnected = deviceSettings.phoneConnected;
    self.doNotDisturb = deviceSettings.doNotDisturb;
    self.notificationCount = deviceSettings.notificationCount;
    if (notificationCount > 99) {
      notificationCount = 99;
    }
    var heartRateNumber = activityInfo.currentHeartRate;
    self.heartRate = heartRateNumber == null ? "--" : heartRateNumber;
  }

  function compare(other as SecondModel?) as Diff {
    if (other == null) {
      return UPDATE_DIFF_ALL;
    }

    if (other.notificationCount == self.notificationCount &&
      other.isPhoneConnected == self.isPhoneConnected &&
      other.doNotDisturb == self.doNotDisturb) {
      if (other.heartRate.equals(self.heartRate)) {
        return UPDATE_DIFF_SECONDS;
      } else {
        return UPDATE_DIFF_SECONDS_AND_PULSE;
      }
    }
    return UPDATE_DIFF_ALL;
  }
}