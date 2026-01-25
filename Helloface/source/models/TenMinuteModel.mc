import Toybox.Time;
import Toybox.Lang;
import Toybox.Application.Storage;
import Toybox.Time.Gregorian;

class TenMinuteModel {
  private var sunriseMoment as Moment?;
  private var sunriseTomorrowMoment as Moment?;
  private var sunsetMoment as Moment?;
  private var sunsetTomorrowMoment as Moment?;
  var sunrise as String;
  var sunriseTomorrow as String;
  var sunset as String;
  var sunsetTomorrow as String;

  function initialize(today as Moment) {
    var here = Position.getInfo().position;
    var tomorrow = today.add(new Time.Duration(Gregorian.SECONDS_PER_DAY));

    self.sunriseMoment = Weather.getSunrise(here, today);
    self.sunriseTomorrowMoment = Weather.getSunrise(here, tomorrow);
    self.sunsetMoment = Weather.getSunset(here, today);
    self.sunsetTomorrowMoment = Weather.getSunset(here, tomorrow);

    self.sunrise = Utils.formatTimeMoment(self.sunriseMoment);
    self.sunriseTomorrow = Utils.formatTimeMoment(self.sunriseTomorrowMoment);
    self.sunset = Utils.formatTimeMoment(self.sunsetMoment);
    self.sunsetTomorrow = Utils.formatTimeMoment(self.sunsetTomorrowMoment);
  }

  function hasSunTimes() as Boolean {
    return self.sunriseMoment != null && self.sunsetMoment != null;
  }

  function isDaytime(now as Moment) {
    if (self.sunriseMoment == null || self.sunsetMoment == null) {
      return true; // best guess
    }

    var isAfterSunrise = now.compare(self.sunriseMoment) >= 0;
    var isBeforeSunset = now.compare(self.sunsetMoment) < 0;

    return isAfterSunrise && isBeforeSunset;
  }

  function getNextSunTimes(now as Moment) as Array<String> {
    var anHourAgo = now.subtract(new Time.Duration(Gregorian.SECONDS_PER_HOUR));

    if (
      self.sunriseMoment == null ||
      self.sunsetMoment == null ||
      self.sunriseTomorrowMoment == null ||
      self.sunsetTomorrowMoment == null
    ) {
      return ["-:--"];
    }

    if (self.sunriseMoment.greaterThan(anHourAgo)) {
      return [self.sunrise, self.sunset];
    }
    if (self.sunsetMoment.greaterThan(anHourAgo)) {
      return [self.sunset, self.sunriseTomorrow];
    }
    return [self.sunriseTomorrow, self.sunsetTomorrow];
  }
}
