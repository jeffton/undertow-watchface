import Toybox.Math;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Time;

class SunFactory {

  static function createSunModel(tenMinuteModel as TenMinuteModel) as SunModel? {
    if (!tenMinuteModel.hasSunTimes()) {
      return null;
    }

    var positionInfo = Position.getInfo();
    if (positionInfo.position == null) {
      return null;
    }

    var latLon = positionInfo.position.toDegrees();
    var latitude = latLon[0].toFloat();
    var longitude = latLon[1].toFloat();

    var sunPosition = calculateSunPosition(Time.now(), latitude, longitude);
    var declination = sunPosition[0];
    var hourAngle = sunPosition[1];

    var sunTrack = calculateSunriseSunsetAzimuth(latitude, declination);

    var model = new SunModel();
    model.minSunAzimuth = sunTrack[0];
    model.maxSunAzimuth = sunTrack[1];
    model.currentSunAzimuth = calculateSunAzimuth(latitude, declination, hourAngle);
    model.isAzimuthClockwise = latitude >= 0;

    return model;
  }

  static function calculateSunPosition(moment as Moment, latitude as Float, longitude as Float) as Array {
    var jd = moment.value() / 86400.0 + 2440587.5;
    var T = (jd - 2451545.0) / 36525.0;

    var L0 = normalizeDegrees(280.46646 + T * (36000.76983 + 0.0003032 * T));
    var M = 357.52911 + T * (35999.05029 - 0.0001537 * T);

    var c = Math.sin(Math.toRadians(M)) * (1.914602 - T * (0.004817 + 0.000014 * T))
      + Math.sin(Math.toRadians(2 * M)) * (0.019993 - 0.000101 * T)
      + Math.sin(Math.toRadians(3 * M)) * 0.000289;
    var trueLongitude = L0 + c;

    var omega = 125.04 - 1934.136 * T;
    var lambda = trueLongitude - 0.00569 - 0.00478 * Math.sin(Math.toRadians(omega));

    var epsilon0 = 23 + (26 + (21.448 - T * (46.815 + T * (0.00059 - T * 0.001813))) / 60.0) / 60.0;
    var epsilon = epsilon0 + 0.00256 * Math.cos(Math.toRadians(omega));
    var eccent = 0.016708634 - T * (0.000042037 + 0.0000001267 * T);

    var declination = Math.toDegrees(Math.asin(Math.sin(Math.toRadians(epsilon)) * Math.sin(Math.toRadians(lambda))));

    var y = Math.pow(Math.tan(Math.toRadians(epsilon / 2.0)), 2);
    var eqTime = 4.0 * Math.toDegrees(
      y * Math.sin(2.0 * Math.toRadians(L0))
      - 2.0 * eccent * Math.sin(Math.toRadians(M))
      + 4.0 * eccent * y * Math.sin(Math.toRadians(M)) * Math.cos(2.0 * Math.toRadians(L0))
      - 0.5 * y * y * Math.sin(4.0 * Math.toRadians(L0))
      - 1.25 * eccent * eccent * Math.sin(2.0 * Math.toRadians(M))
    );
    var utcSeconds = moment.value();
    var utcMinutes = (utcSeconds / 60.0) - 1440.0 * Math.floor((utcSeconds / 60.0) / 1440.0);
    var trueSolarTime = utcMinutes + eqTime + 4.0 * longitude;
    trueSolarTime = trueSolarTime - 1440.0 * Math.floor(trueSolarTime / 1440.0);

    var hourAngle = trueSolarTime / 4.0 - 180.0;
    if (hourAngle < -180.0) {
      hourAngle += 360.0;
    }

    return [declination, hourAngle];
  }

  static function calculateSunAzimuth(latitude as Float, declination as Float, hourAngle as Float) as Float {
    var latRad = Math.toRadians(latitude);
    var decRad = Math.toRadians(declination);
    var haRad = Math.toRadians(hourAngle);
    return hourAngleToAzimuth(haRad, latRad, decRad);
  }

  static function calculateSunriseSunsetAzimuth(latitude as Float, declination as Float) as Array {
    var latRad = Math.toRadians(latitude);
    var decRad = Math.toRadians(declination);
    var zenithRad = Math.toRadians(90.833);
    var cosH0 = (Math.cos(zenithRad) - Math.sin(latRad) * Math.sin(decRad)) / (Math.cos(latRad) * Math.cos(decRad));

    if (cosH0 > 1 || cosH0 < -1) {
      var az = calculateSunAzimuth(latitude, declination, 0.0);
      return [az, az];
    }

    var hourAngle = Math.acos(cosH0);
    var hourAngleDegrees = Math.toDegrees(hourAngle);
    var sunriseAz = calculateSunAzimuth(latitude, declination, -hourAngleDegrees);
    var sunsetAz = calculateSunAzimuth(latitude, declination, hourAngleDegrees);

    return [sunriseAz, sunsetAz];
  }

  private static function normalizeDegrees(value as Float) as Float {
    var rotations = Math.floor(value / 360.0);
    var normalized = value - rotations * 360.0;
    if (normalized < 0) {
      normalized += 360.0;
    }
    return normalized;
  }

  private static function hourAngleToAzimuth(hourAngleRad as Float, latRad as Float, decRad as Float) as Float {
    var numerator = -Math.sin(hourAngleRad) * Math.cos(decRad);
    var denominator = Math.cos(latRad) * Math.sin(decRad) - Math.sin(latRad) * Math.cos(decRad) * Math.cos(hourAngleRad);
    var azimuth = Math.toDegrees(Math.atan2(numerator, denominator));
    if (azimuth < 0) {
      azimuth += 360;
    }
    return azimuth;
  }
}
