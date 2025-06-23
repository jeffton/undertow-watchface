import Toybox.Lang;
import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Activity;
import Toybox.Time;


(:background)
class ActivityCountService {

  function onActivityCompleted(activity as {
    :sport as Activity.Sport,
    :subSport as Activity.SubSport
    }) as Void 
  {
    if (!activityTypeIsValid(activity)) {
      Background.exit(null);
      return; 
    }

    var today = Time.today();
    var storedCount = readStoredCount(today);
    writeStoredCount(today, storedCount + 1);

    Background.exit(null);
  }

  function readStoredCount(today as Moment) as Number {
    var stored = Storage.getValue("activity-count");
    if (stored instanceof Dictionary && stored.hasKey("date")) {
      var storedDate = stored.get("date") as Number;
      if (storedDate == today.value()) {
        var storedCount = stored.get("count") as Number;
        return storedCount;
      }
    }
    return 0;
  }

  function writeStoredCount(today as Moment, count as Number) {
    var stored = { "date" => today.value(), "count" => count };
    Storage.setValue("activity-count", stored);
  }

  function activityTypeIsValid(activity as {
    :sport as Activity.Sport,
    :subSport as Activity.SubSport
    })
  {
    switch (activity.get(:sport)) {
      case Activity.SPORT_HEALTH_MONITORING:
      case Activity.SPORT_VIDEO_GAMING:
      case Activity.SPORT_INVALID:
        return false;
      default:
        return true;
    }
  }

/*
  private function getActivityCount(today as Moment) as Number {
    var userActivityIterator = UserProfile.getUserActivityHistory();
    
    var dayCount = 0;
    var todayFit = getMidnightAsFitDate(today);

    var activityData = userActivityIterator.next();
    while (activityData != null && dayCount < 99) {
      var type = activityData.type;
      var startTime = activityData.startTime;

      if (
        type != null && 
        startTime != null && 
        startTime.greaterThan(todayFit) && 
        type != Activity.SPORT_HEALTH_MONITORING &&
        type != Activity.SPORT_VIDEO_GAMING &&
        type != Activity.SPORT_INVALID
      ) {
        dayCount++;
      }
  
      activityData = userActivityIterator.next();
    }

    return dayCount;
  }

  private function getMidnightAsFitDate(today as Moment) as Moment {
    var secondsToGarminEpoch = 631065600;
    return today.subtract(new Time.Duration(secondsToGarminEpoch));
  }
*/
  

}