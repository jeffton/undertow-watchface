import Toybox.Position;
import Toybox.Time;
import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Activity;


(:background)
class WeatherService {
  function onTemporalEvent() as Void {
    var positionInfo = Position.getInfo();
    var position = positionInfo.position;
    if (position == null) {
      Background.exit(null);
      return;
    }

    var lastData = Storage.getValue("weather") as Dictionary?;
    var activityService = new ActivityCountService();
    var hasPendingSync = activityService.hasPendingSync();
    if (!shouldSync(position, lastData, hasPendingSync)) {
      Background.exit(null);
      return;
    }

    requestData(position);
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

    var positionInfo = Position.getInfo();
    var position = positionInfo.position;
    if (position == null) {
      Background.exit(null);
      return;
    }

    var lastData = Storage.getValue("weather") as Dictionary?;
    if (!shouldSync(position, lastData, true)) {
      Background.exit(null);
      return;
    }

    requestData(position);
  }

  function update(lastData as Dictionary?) as Void {
    var here = Position.getInfo().position;
    var activityService = new ActivityCountService();
    var hasPendingSync = activityService.hasPendingSync();
    if (shouldSync(here, lastData, hasPendingSync)) {
      try {
        Background.registerForTemporalEvent(Time.now());
      } catch (e) {
      }
    }
  }

  function shouldSync(
    position as Position.Location?,
    lastData as Dictionary?,
    hasPendingSync as Boolean
  ) as Boolean {
    if (position == null || !System.getDeviceSettings().phoneConnected) {
      return false;
    }
    if (hasPendingSync) {
      return true;
    }
    if (!(lastData instanceof Dictionary)) {
      return true;
    }
  
    var lastRequestTime = lastData.get("requestTime");
    var lastPosition = lastData.get("requestPosition") as [Double, Double] or Null;

    if (!(lastRequestTime instanceof Number) || lastPosition == null) {
      return true;
    }

    var timeSinceLastRequest = Time.now().subtract(new Time.Moment(lastRequestTime)) as Time.Duration;
    var oneHour = new Time.Duration(3540);

    if (timeSinceLastRequest.greaterThan(oneHour)) {
      return true;
    }

    var latlon = position.toDegrees();
    var distanceToLastRequest = distance(latlon[0], latlon[1], lastPosition[0], lastPosition[1]);
    return (distanceToLastRequest >= 1);
  }

  function distance(lat1 as Double, lon1 as Double, lat2 as Double, lon2 as Double) as Double {
    var x = Math.toRadians((lon2 - lon1)) * Math.cos(Math.toRadians((lat1 + lat2) / 2));
    var y = Math.toRadians(lat2 - lat1);
    var distance = Math.sqrt(x * x + y * y) * 6371;
    return distance;
  }

  function requestData(position as Position.Location) as Void {
    var latlon = position.toDegrees();
    var lastWorkout = new ActivityCountService().readLastWorkout();
    var params = getParams(latlon, lastWorkout);

    var headers = {
      "x-api-key" => WakeServiceSettings.API_KEY,
    };

    var options = {
      :headers => headers
    };

    Communications.makeWebRequest(
        WakeServiceSettings.URL,
        params,
        options,
        method(:onResponse)
    );
  }

  (:debug)
  function getParams(
    latlon as [Double, Double],
    lastWorkout as Number
  ) as Dictionary {
    return {
      "lat" => latlon[0],
      "lon" => latlon[1],
      "format" => "compact",
      "lastWorkout" => lastWorkout
    };
  }

  (:release)
  function getParams(
    latlon as [Double, Double],
    lastWorkout as Number
  ) as Dictionary {
    return {
      "lat" => latlon[0],
      "lon" => latlon[1],
      "format" => "compact",
      "logLocation" => 1,
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
