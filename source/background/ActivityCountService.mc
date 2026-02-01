import Toybox.Lang;
import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Activity;
import Toybox.Time;


(:background)
class ActivityCountService {
  const STORAGE_KEY as String = "activity-count";
  const DATE_KEY as String = "date";
  const COUNT_KEY as String = "count";
  const LAST_WORKOUT_KEY as String = "lastWorkout";
  const PENDING_SYNC_KEY as String = "pendingSync";

  function onActivityCompleted(activity as {
    :sport as Activity.Sport,
    :subSport as Activity.SubSport
    }) as Boolean
  {
    if (!activityTypeIsValid(activity)) {
      return false;
    }

    var now = Time.now();
    var today = Time.today();
    var storedState = readStoredState();
    var storedCount = readStoredCountFromState(storedState, today);
    var nextState = buildState(today, storedCount + 1, now.value(), true, storedState);

    Storage.setValue(STORAGE_KEY, nextState);
    return true;
  }

  function readStoredCount(today as Moment) as Number {
    var storedState = readStoredState();
    return readStoredCountFromState(storedState, today);
  }

  function readLastWorkout() as Number {
    var storedState = readStoredState();
    if (storedState != null && storedState.hasKey(LAST_WORKOUT_KEY)) {
      var storedLastWorkout = storedState.get(LAST_WORKOUT_KEY);
      if (storedLastWorkout instanceof Number) {
        return storedLastWorkout;
      }
    }
    return 0;
  }

  function hasPendingSync() as Boolean {
    var storedState = readStoredState();
    if (storedState != null && storedState.hasKey(PENDING_SYNC_KEY)) {
      var pending = storedState.get(PENDING_SYNC_KEY);
      if (pending instanceof Boolean) {
        return pending;
      }
    }
    return false;
  }

  function clearPendingSync() as Void {
    var storedState = readStoredState();
    if (storedState == null) {
      return;
    }
    storedState.put(PENDING_SYNC_KEY, false);
    Storage.setValue(STORAGE_KEY, storedState);
  }

  function readStoredState() as Dictionary? {
    var stored = Storage.getValue(STORAGE_KEY);
    if (stored instanceof Dictionary) {
      return stored;
    }
    return null;
  }

  function readStoredCountFromState(storedState as Dictionary?, today as Moment) as Number {
    if (storedState != null && storedState.hasKey(DATE_KEY)) {
      var storedDate = storedState.get(DATE_KEY) as Number;
      if (storedDate == today.value()) {
        var storedCount = storedState.get(COUNT_KEY) as Number;
        return storedCount;
      }
    }
    return 0;
  }

  function buildState(
    today as Moment,
    count as Number,
    lastWorkout as Number,
    pendingSync as Boolean,
    storedState as Dictionary?
  ) as Dictionary {
    var state = storedState;
    if (state == null) {
      state = {};
    }
    state.put(DATE_KEY, today.value());
    state.put(COUNT_KEY, count);
    state.put(LAST_WORKOUT_KEY, lastWorkout);
    state.put(PENDING_SYNC_KEY, pendingSync);
    return state;
  }

  function activityTypeIsValid(activity as {
    :sport as Activity.Sport,
    :subSport as Activity.SubSport
    }) as Boolean
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
