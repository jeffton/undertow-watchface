import Toybox.Time;
import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Activity;


(:background)
class WakeSyncService {
  function onTemporalEvent() as Void {
    var lastData = Storage.getValue("weather") as Dictionary?;
    var activityService = new ActivityCountService();
    var hasPendingSync = activityService.hasPendingSync();
    if (!shouldSync(lastData, hasPendingSync)) {
      Background.exit(null);
      return;
    }

    requestData();
  }

  function onActivityCompleted(activity as {
    :sport as Activity.Sport,
    :subSport as Activity.SubSport
    }) as Void
  {
    var activityService = new ActivityCountService();
    var updated = activityService.onActivityCompleted(activity);
    if (!updated) {
      Background.exit(null);
      return;
    }

    var lastData = Storage.getValue("weather") as Dictionary?;
    if (!shouldSync(lastData, true)) {
      Background.exit(null);
      return;
    }

    requestData();
  }

  function update(lastData as Dictionary?) as Void {
    var activityService = new ActivityCountService();
    var hasPendingSync = activityService.hasPendingSync();
    if (shouldSync(lastData, hasPendingSync)) {
      try {
        Background.registerForTemporalEvent(Time.now());
      } catch (e) {
      }
    }
  }

  function shouldSync(
    lastData as Dictionary?,
    hasPendingSync as Boolean
  ) as Boolean {
    if (!System.getDeviceSettings().phoneConnected) {
      return false;
    }
    if (hasPendingSync) {
      return true;
    }
    if (!(lastData instanceof Dictionary)) {
      return true;
    }
  
    var lastRequestTime = lastData.get("requestTime");

    if (!(lastRequestTime instanceof Number)) {
      return true;
    }

    var timeSinceLastRequest = Time.now().subtract(new Time.Moment(lastRequestTime)) as Time.Duration;
    var syncInterval = new Time.Duration(1740);
    return timeSinceLastRequest.greaterThan(syncInterval);
  }

  function requestData() as Void {
    var lastWorkout = new ActivityCountService().readLastWorkout();
    var body = getBody(lastWorkout);

    var headers = {
      "x-api-key" => WakeServiceSettings.API_KEY,
      "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
    };

    var options = {
      :method => Communications.HTTP_REQUEST_METHOD_POST,
      :headers => headers
    };

    Communications.makeWebRequest(
        WakeServiceSettings.URL,
        body,
        options,
        method(:onResponse)
    );
  }

  (:debug)
  function getBody(lastWorkout as Number) as Dictionary {
    return {
      "format" => "compact",
      "awake" => 1,
      "lastWorkout" => 0
    };
  }

  (:release)
  function getBody(lastWorkout as Number) as Dictionary {
    return {
      "format" => "compact",
      "awake" => 1,
      "lastWorkout" => lastWorkout
    };
  }

  function onResponse(
    responseCode as Number,
    data as Null or Dictionary or String or PersistedContent.Iterator) as Void
  {
    if (data instanceof Dictionary && data.hasKey("forecast")) {
      new ActivityCountService().clearPendingSync();
      Background.exit(data);
    } else {
      Background.exit(null);
    }
  }
}
