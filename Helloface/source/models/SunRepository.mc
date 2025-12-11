import Toybox.Position;
import Toybox.Time;

class SunRepository {

  function getSunModel(tenMinuteModel as TenMinuteModel) as SunModel {
    var model = new SunModel();
    if (!tenMinuteModel.hasSunTimes()) {
      return model;
    }
    var positionInfo = Position.getInfo();
    if (positionInfo == null || positionInfo.position == null) {
      return model;
    }

    var here = positionInfo.position;
    var latLon = here.toDegrees();
    if (latLon == null || latLon.size() < 2) {
      return model;
    }

    var latitude = latLon[0].toFloat();
    var longitude = latLon[1].toFloat();

    var sunPosition = SunCalculator.calculateSunPosition(Time.now(), latitude, longitude);
    var sunTrack = SunCalculator.calculateSunriseSunsetAzimuth(latitude, sunPosition.declination);

    model.minSunAzimuth = sunTrack.sunrise;
    model.maxSunAzimuth = sunTrack.sunset;
    model.currentSunAzimuth = SunCalculator.calculateSunAzimuth(latitude, sunPosition.declination, sunPosition.hourAngle);
    model.isAzimuthClockwise = latitude >= 0;

    return model;
  }
}
