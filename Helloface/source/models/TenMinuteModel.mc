import Toybox.Time;
import Toybox.Lang;
import Toybox.Application.Storage;
import Toybox.Time.Gregorian;
import Toybox.SensorHistory;

class TenMinuteModel {

  private var sunriseMoment as Moment?;
  private var sunriseTomorrowMoment as Moment?;
  private var sunsetMoment as Moment?;
  var sunrise as String;
  var sunriseTomorrow as String;
  var sunset as String;
  var pressureChange as Float or Null;

  function initialize(today as Moment) {
    var here = Position.getInfo().position;
    var tomorrow = today.add(new Time.Duration(Gregorian.SECONDS_PER_DAY));

    self.sunriseMoment = Weather.getSunrise(here, today);
    self.sunriseTomorrowMoment = Weather.getSunrise(here, tomorrow);
    self.sunsetMoment = Weather.getSunset(here, today);

    self.sunrise = Utils.formatTimeMoment(self.sunriseMoment);
    self.sunriseTomorrow = Utils.formatTimeMoment(self.sunriseTomorrowMoment);
    self.sunset = Utils.formatTimeMoment(self.sunsetMoment);

    self.pressureChange = getPressureChange();
  }

  function isDaytime(now as Moment) {
     if (self.sunriseMoment == null || self.sunsetMoment == null) {
      return true; // best guess
    }

    var sunriseInPast = self.sunriseMoment.lessThan(now);
    var sunsetInFuture = self.sunsetMoment.greaterThan(now);

    return sunriseInPast && sunsetInFuture;
  }

  function getNextSunTime(now as Moment) as String {
    var anHourAgo = now.subtract(new Time.Duration(Gregorian.SECONDS_PER_HOUR));

    if (self.sunriseMoment == null || self.sunsetMoment == null || self.sunriseTomorrowMoment == null) {
      return "-:--";
    }

    if (self.sunriseMoment.greaterThan(anHourAgo)) {
      return self.sunrise;
    }
    if (self.sunsetMoment.greaterThan(anHourAgo)) {
      return self.sunset;
    }
    return self.sunriseTomorrow;
  }

  function getPressureChange() as Float or Null {
    var oneHour = new Time.Duration(Gregorian.SECONDS_PER_HOUR);
    var pressureIterator = SensorHistory.getPressureHistory({
        :period => oneHour
    });

    var halfAnHourAgo = Time.now().subtract(new Time.Duration(1800));

    var firstHalfSum = 0.0f;
    var firstHalfCount = 0;
    var secondHalfSum = 0.0f;
    var secondHalfCount = 0;

    var sample = pressureIterator.next();
    while (sample != null) {
        if (sample.data != null) {
            if (sample.when.lessThan(halfAnHourAgo)) {
                firstHalfSum += sample.data;
                firstHalfCount++;
            } else {
                secondHalfSum += sample.data;
                secondHalfCount++;
            }
        }
        sample = pressureIterator.next();
    }

    if (firstHalfCount > 0 && secondHalfCount > 0) {
        var firstHalfAvg = firstHalfSum / firstHalfCount;
        var secondHalfAvg = secondHalfSum / secondHalfCount;
        // convert from Pa to hPa
        return (secondHalfAvg - firstHalfAvg) / 100.0;
    }
    return null;
  }
}