import Toybox.Position;
import Toybox.Time;
import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.Application;
import Toybox.Application.Storage;


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
    if (position == null) {
      return false;
    }
    if (!(lastData instanceof Dictionary)) {
      return true;
    }
  
    var lastRequestTime = lastData.get("requestTime");
    var lastPosition = lastData.get("requestPosition");

    if (!(lastRequestTime instanceof Number && lastPosition instanceof Dictionary)) {
      return true;
    }
    
    var timeSinceLastRequest = Time.now().subtract(new Time.Moment(lastRequestTime)) as Time.Duration;
    var sixHours = new Time.Duration(21600);

    if (timeSinceLastRequest.greaterThan(sixHours)) {
      return true;
    }

    var lastLat = lastPosition.get("lat");
    var lastLon = lastPosition.get("lon");
    var latlon = position.toDegrees();
    var distanceToLastRequest = distance(latlon[0], latlon[1], lastLat, lastLon);
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
    
    var params = {
      "lat" => latlon[0],
      "lon" => latlon[1],
      "accuracy" => accuracy
    };

    Communications.makeWebRequest(
        "https://yrproxy-418768340557.europe-north2.run.app/",
        params,
        {},
        method(:onResponse)
    );
  }

  function onResponse(
    responseCode as Number,
    data as Null or Dictionary or String or PersistedContent.Iterator) as Void
  {
    if (data instanceof Dictionary && data.hasKey("forecast")) {
      Storage.setValue("sea-data", data);
      Background.exit(data);
    } else {
      Background.exit(null);
    }
  }
} 