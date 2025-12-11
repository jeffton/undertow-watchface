import Toybox.Position;
import Toybox.Time;

class SunRepository {

  function getSunModel(tenMinuteModel as TenMinuteModel) as SunModel? {
    if (!tenMinuteModel.hasSunTimes()) {
      return null;
    }
    var position = Position.getInfo().position;
    if (position == null) {
      return null;
    }

    var latLon = position.toDegrees();
    var latitude = latLon[0].toFloat();
    var longitude = latLon[1].toFloat();

    var sunPosition = SunCalculator.calculateSunPosition(Time.now(), latitude, longitude);
    var sunTrack = SunCalculator.calculateSunriseSunsetAzimuth(latitude, sunPosition.declination);

    var model = new SunModel();
    model.minSunAzimuth = sunTrack.sunrise;
    model.maxSunAzimuth = sunTrack.sunset;
    model.currentSunAzimuth = SunCalculator.calculateSunAzimuth(latitude, sunPosition.declination, sunPosition.hourAngle);
    model.isAzimuthClockwise = latitude >= 0;

    return model;
  }
}
