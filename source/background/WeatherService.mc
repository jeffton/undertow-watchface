import Toybox.Position;
import Toybox.Time;
import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.Application;


(:background)
class WeatherService {
  function onTemporalEvent() {
    var positionInfo = Position.getInfo();

    if (positionInfo.position == null) {
      Background.exit(null);
    } else {
      requestData(positionInfo.position, positionInfo.accuracy);
    }
  }

  function update(lastData as Dictionary?) {
    var here = Position.getInfo().position;
    if (shouldUpdateForecast(here, lastData)) {
      try {
        Background.registerForTemporalEvent(Time.now());
      } catch (e) {
        // we just ran a temporal event, ignore and let next update handle it
      }
    }
  }

  function shouldUpdateForecast(position as Position.Location?, lastData as Dictionary?) as Boolean {
    if (position == null || !System.getDeviceSettings().phoneConnected) {
      return false;
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
    var oneHour = new Time.Duration(3540); // 59 minutes really

    if (timeSinceLastRequest.greaterThan(oneHour)) {
      return true;
    }

    var latlon = position.toDegrees();
    var distanceToLastRequest = distance(latlon[0], latlon[1], lastPosition[0], lastPosition[1]);
    return (distanceToLastRequest >= 1);
  }

  function distance(lat1, lon1, lat2, lon2) {
    var x = Math.toRadians((lon2 - lon1)) * Math.cos(Math.toRadians((lat1 + lat2) / 2));
    var y = Math.toRadians(lat2 - lat1);
    var distance = Math.sqrt(x * x + y * y) * 6371; // average earth radius in km
    return distance;
  }

  function requestData(position as Position.Location, accuracy as Position.Quality) {
    var latlon = position.toDegrees();

    var params = getParams(latlon, accuracy);

    var headers = {
      "x-api-key" => WakeServiceSettings.API_KEY
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
  function getParams(latlon as [Double, Double], accuracy as Position.Quality) as Dictionary {
    return {
      "lat" => latlon[0],
      "lon" => latlon[1],
      "accuracy" => accuracy
    };
  }

  (:release)
  function getParams(latlon as [Double, Double], accuracy as Position.Quality) as Dictionary {
    return {
      "lat" => latlon[0],
      "lon" => latlon[1],
      "accuracy" => accuracy,
      "logLocation" => 1
    };
  }

  function onResponse(
    responseCode as Number,
    data as Null or Dictionary or String or PersistedContent.Iterator) as Void
  {
    if (data instanceof Dictionary && data.hasKey("forecast")) {
      Background.exit(data);
    } else {
      Background.exit(null);
    }
  }
} 
