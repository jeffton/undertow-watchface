import Toybox.Lang;
import Toybox.System;
import Toybox.Activity;
import Toybox.Time.Gregorian;
import Toybox.ActivityMonitor;
import Toybox.Time;
import Toybox.Weather;
import Toybox.PersistedContent;

class MinuteModel {
  var time as String;
  var bodyBattery as Number?;
  var stress as Numeric?;
  var recoveryTime as Number;
  var activeMinutes as DailyWeekly;
  var steps as DailyWeekly;
  var battery as Number;
  var sunTime as String?;
  var altitude as String;
  var pressure as Float?;
 
  function initialize(updateTime as UpdateTime, tenMinuteModel as TenMinuteModel) {
    var now = Time.now();
    var activityMonitorInfo = ActivityMonitor.getInfo();
    var activityInfo = Activity.getActivityInfo();

    self.time = getTime(updateTime.clockTime);
    self.bodyBattery = getBodyBattery();
    self.stress = getStress();
    self.recoveryTime = getRecoveryTime(activityMonitorInfo);
    self.activeMinutes = getActiveMinutes(activityMonitorInfo);
    self.steps = getSteps(activityMonitorInfo);
    self.battery = getBattery();
    self.sunTime = getNextSunTime(tenMinuteModel, now);
    self.altitude = getAltitude(activityInfo);
    self.pressure = getPressure(activityInfo);
  }

  function getAltitude(activityInfo as Activity.Info) as String {
    var altitude = activityInfo.altitude;
    if (altitude == null) {
      return "-";
    }

    altitude = Math.round(altitude);
    return altitude.format("%i") + "m";
  }

  private function getPressure(activityInfo as Activity.Info) as Float? {
    var pressurePa = activityInfo.ambientPressure;
    if (pressurePa == null) {
      return null;
    }
    return pressurePa / 100.0;
  }

  private function getTime(clockTime as ClockTime) {
    return Utils.formatTime(
      clockTime.hour,
      clockTime.min
    );
  }

  private function getBodyBattery() as Number? {
    var history = SensorHistory.getBodyBatteryHistory({ :period => 20, :order => SensorHistory.ORDER_NEWEST_FIRST });
    
    var last = history.next();
    while (last != null) {
      var lastData = last.data;
      if (lastData != null) {
        return lastData;
      }
      last = history.next();
    }

    return null;
  }

  private function getStress() as Numeric? {
    var history = SensorHistory.getStressHistory({ :period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST });
    var last = history.next();
    if (last == null) {
      return null;
    }
    return last.data;
  }
  
  private function getRecoveryTime(activityMonitorInfo as ActivityMonitor.Info) {
    var hours = activityMonitorInfo.timeToRecovery;
    return hours == null ? 0 : hours;
  }

  private function getActiveMinutes(activityMonitorInfo as ActivityMonitor.Info) as DailyWeekly {
    var today = activityMonitorInfo.activeMinutesDay.total;
    var week = activityMonitorInfo.activeMinutesWeek.total;
    var goal = activityMonitorInfo.activeMinutesWeekGoal;
    if (goal == null) {
      goal = 0;
    }
    return new DailyWeekly(today, week, goal);
  }

  private function getSteps(activityMonitorInfo as ActivityMonitor.Info) as DailyWeekly {
    return new DailyWeekly(activityMonitorInfo.steps, activityMonitorInfo.steps, activityMonitorInfo.stepGoal);
  }

  private function getBattery() {
    return System.getSystemStats().battery;
  }

  private function getNextSunTime(tenMinuteModel as TenMinuteModel, now as Moment) as String {
    return tenMinuteModel.getNextSunTime(now);
  }
}