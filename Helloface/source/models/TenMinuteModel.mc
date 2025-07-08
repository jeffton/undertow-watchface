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

    // We will compare the first 15 minutes of the hour period with the last 15 minutes.
    var startOfLast15Mins = Time.now().subtract(new Time.Duration(900));
    var endOfFirst15Mins = Time.now().subtract(new Time.Duration(2700)); // 45 mins ago

    var firstIntervalSum = 0.0f;
    var firstIntervalCount = 0;
    var lastIntervalSum = 0.0f;
    var lastIntervalCount = 0;

    // compare the average of the first 15 minutes of the hour-long period with 
    // the average of the last 15 minutes
    var sample = pressureIterator.next();
    while (sample != null) {
        if (sample.data != null) {
            if (sample.when.greaterThan(startOfLast15Mins)) {
                lastIntervalSum += sample.data;
                lastIntervalCount++;
            } else if (sample.when.lessThan(endOfFirst15Mins)) {
                firstIntervalSum += sample.data;
                firstIntervalCount++;
            }
        }
        sample = pressureIterator.next();
    }

    if (firstIntervalCount > 0 && lastIntervalCount > 0) {
        var firstIntervalAvg = firstIntervalSum / firstIntervalCount;
        var lastIntervalAvg = lastIntervalSum / lastIntervalCount;
        // convert from Pa to hPa
        return (lastIntervalAvg - firstIntervalAvg) / 100.0;
    }
    return null;
  }
}