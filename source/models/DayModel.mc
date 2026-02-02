import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.System;

class DayModel {
  var hasWorkoutToday as Boolean;
  var date as String;
  var alarm as Boolean;
  var weekday as Number;

  function initialize(updateTime as UpdateTime) {
    var deviceSettings = System.getDeviceSettings();
    var activityCountService = new ActivityCountService();

    self.date = getDate(updateTime.today);
    self.hasWorkoutToday = activityCountService.hasWorkoutToday(updateTime.today);
    self.alarm = getAlarm(deviceSettings);
    self.weekday = getWeekday(updateTime.today);
  }

  private function getDate(today as Moment) {
    var dateInfo = Gregorian.info(today, Time.FORMAT_LONG);
    return Lang.format("$1$ $2$", [dateInfo.day_of_week, dateInfo.day]).toUpper();
  }

  private function getAlarm(deviceSettings as DeviceSettings) {
    return deviceSettings.alarmCount > 0;
  }

  private function getWeekday(today as Moment) as Number {
    var info = Gregorian.info(today, Time.FORMAT_SHORT);
    var day = info.day_of_week - 1; // this gets us 0 = sunday, 1 = monday, ...
    if (day == 0) {
      day = 7;
    }
    return day;
  }

}