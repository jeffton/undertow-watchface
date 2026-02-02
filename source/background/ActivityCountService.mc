import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Activity;
import Toybox.Lang;
import Toybox.Time;


(:background)
class ActivityCountService {
  const STORAGE_KEY as String = "activity-count";
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
    var storedState = readStoredState();
    var nextState = buildState(now.value(), true, storedState);

    Storage.setValue(STORAGE_KEY, nextState);
    return true;
  }

  function hasWorkoutToday(today as Moment) as Boolean {
    var lastWorkout = readLastWorkout();
    if (lastWorkout <= 0) {
      return false;
    }
    return lastWorkout >= today.value();
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
      return stored as Dictionary;
    }
    return null;
  }

  function buildState(
    lastWorkout as Number,
    pendingSync as Boolean,
    storedState as Dictionary?
  ) as Dictionary {
    var state = storedState;
    if (state == null) {
      state = {};
    }
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
}
