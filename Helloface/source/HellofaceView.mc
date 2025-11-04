import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.Weather;
import Toybox.ActivityMonitor;
import Toybox.Media;
import Toybox.Time.Gregorian;
import Toybox.Time;

class HellofaceView extends WatchUi.WatchFace {
  var models as IModelsRepository;
  var bitmaps as Bitmaps;

  var previousSecond as SecondModel?;

  var isHighPowerMode = true;
  var useDemoRepo = false;

  function initialize() {
    WatchFace.initialize();

    self.bitmaps = new Bitmaps();
    if (useDemoRepo) {
      self.models = new DemoModelsRepository() as IModelsRepository;
    } else {
      self.models = new ModelsRepository() as IModelsRepository;
    }
  }

  function onWeatherUpdated(data as Dictionary) {
    self.models.onWeatherUpdated(data);
    WatchUi.requestUpdate();
  }

  // Load your resources here
  function onLayout(dc as Dc) as Void {}

  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() as Void {}

  // Update the view
  function onUpdate(dc as Dc) as Void {
    models.updateModels();

    dc.setClip(0, 0, 176, 176);

    drawMainScreen(dc);
    drawSubScreen(dc);

    previousSecond = models.secondModel;
  }

  function onPartialUpdate(dc as Graphics.Dc) as Void {
    if (!models.updateModelsPartial()) {
      return;
    }

    var diff = self.models.secondModel.compare(previousSecond);
    previousSecond = self.models.secondModel;
    
    switch (diff) {
      case SecondModel.UPDATE_DIFF_SECONDS:
        drawSeconds(dc, true);
        break;
      case SecondModel.UPDATE_DIFF_SECONDS_AND_PULSE:
        dc.setClip(
            176 - 67, // left of seconds
            26, // top of pulse number
            55, // to right of pulse number
            82 // to bottom of seconds
          ); 

          drawPulse(dc);
          drawSeconds(dc, false);
        break;
      case SecondModel.UPDATE_DIFF_ALL:
          dc.setClip(
            176 - 67, // left of seconds
            26, // top of pulse number
            65, // to right edge -2px
            88 // to bottom of pulse
          );

          drawPulse(dc);
          drawSeconds(dc, false);
          drawNotifications(dc);
        break;
    }
  }

  function drawSeconds(dc as Dc, setClip as Boolean) {
    var x = 176 - 67;
    var y = 80;

    if (setClip) {
      dc.setClip(x, y + 5, 21, 22);
    }

    // custom background to not overlap alarm indicator
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.fillRectangle(x, y + 5, 21, 22);

    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.drawText(
      x,
      y,
      Graphics.FONT_GLANCE_NUMBER,
      self.models.secondModel.seconds,
      Graphics.TEXT_JUSTIFY_LEFT
    );
  }

  function drawMainScreen(dc as Dc) {
    // Background
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.fillRectangle(0, 0, 176, 176);

    var isDaytime = self.models.tenMinuteModel.isDaytime(Time.now());

    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    // all of these need white on transparent
    drawDate(dc);
    drawWeather(dc, isDaytime);
    drawSunTime(dc);
    if (!drawSeaTemperature(dc)) {
      drawAltitude(dc);
    }
    drawTime(dc);
    drawAlarm(dc);
    drawBattery(dc);
    drawRecoveryTime(dc);
    drawBarometer(dc);

    // these set varying colors
    drawSteps(dc);
    drawActiveMinutes(dc);
    drawNotifications(dc);
    drawActivityCount(dc);
  }

  function drawDate(dc as Dc) {
    dc.drawText(
      68,
      0,
      Graphics.FONT_GLANCE,
      self.models.dayModel.date,
      Graphics.TEXT_JUSTIFY_CENTER
    );
  }

  function drawWeather(dc as Dc, isDaytime as Boolean) {
    drawWeatherCondition(dc, isDaytime);

    dc.drawText(
      30,
      20,
      Graphics.FONT_GLANCE,
      self.models.weatherModel.temperature,
      Graphics.TEXT_JUSTIFY_LEFT
    );

    dc.drawText(
      80,
      20,
      Graphics.FONT_GLANCE,
      self.models.weatherModel.windSpeed,
      Graphics.TEXT_JUSTIFY_LEFT
    );

    if (self.models.weatherModel.windDirection != null) {
      drawWindBearing(dc, 68, 33, self.models.weatherModel.windDirection);
    }

    drawUvIndex(dc);
    drawPrecipitation(dc);
  }

  function drawUvIndex(dc as Dc) {
    if (self.models.weatherModel.uvIndex != null) {
      var x = 92;
      var y = 40;

      dc.fillRectangle(x-10, y+4, 20, 17);
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
      dc.drawText(x, y, Graphics.FONT_TINY, self.models.weatherModel.uvIndex, Graphics.TEXT_JUSTIFY_CENTER);
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }
  }


  function drawWeatherCondition(dc as Dc, isDaytime as Boolean) {
    var x = 10;
    var y = 24;

    if (self.models.weatherModel.condition != null) {
      var condition = self.models.weatherModel.condition as String;

      if (
        condition.equals("clear") ||
        condition.equals("fair") ||
        condition.equals("partly cloudy") ||
        condition.equals("cloudy")
      ) {
        var cloudCover = self.models.weatherModel.cloudCover as Number;
        
        if (cloudCover >= 90) {
          var cloudCoverLow = self.models.weatherModel.cloudCoverLow;
          if (cloudCoverLow != null && cloudCoverLow >= 70) {
            dc.drawBitmap(x, y, bitmaps.weatherClouds.getBitmap());
          } else {
            dc.drawBitmap(x, y, bitmaps.weatherCloud.getBitmap());
          }
        } else {
          // Draw sun or moon
          var baseBitmap = isDaytime ? bitmaps.weatherSun : bitmaps.weatherMoon;
          dc.drawBitmap(x, y, baseBitmap.getBitmap());

          // Draw cloud overlay
          if (cloudCover >= 70) {
            dc.drawBitmap(x, y, bitmaps.weatherCloud80.getBitmap());
          } else if (cloudCover >= 50) {
            dc.drawBitmap(x, y, bitmaps.weatherCloud60.getBitmap());
          } else if (cloudCover >= 30) {
            dc.drawBitmap(x, y, bitmaps.weatherCloud40.getBitmap());
          } else if (cloudCover >= 10) {
            dc.drawBitmap(x, y, bitmaps.weatherCloud20.getBitmap());
          }
        }
      } else {
        var bitmap = getFallbackWeatherBitmap(condition);
        dc.drawBitmap(x, y, bitmap.getBitmap());
      }
    }
  }

  function drawWindBearing(dc as Dc, x, y, angle) {
    angle = -angle - 90; // wind bearing is 0 = North and clockwise, also it's actually direction so we flip it 180 (-90 instead of +90)
    var radians = Math.toRadians(angle);
    var radius = 8;
    var cos = (radius - 3) * Math.cos(radians);
    var sin = - (radius - 3) * Math.sin(radians); // y axis is inverted
    var cos0 = radius * Math.cos(radians);
    var sin0 = - radius * Math.sin(radians); // y axis is inverted
    dc.setPenWidth(3);
    dc.drawLine(Math.round(x - cos0), Math.round(y - sin0), Math.round(x + cos), Math.round(y + sin));

    var angleArrowLeft = radians - 1.5;
    var angleArrowRight = radians + 1.5;
    var arrowRadius = 4;

    var cos1 = arrowRadius * Math.cos(angleArrowLeft);
    var cos2 = arrowRadius * Math.cos(angleArrowRight);
    var sin1 = - arrowRadius * Math.sin(angleArrowLeft);
    var sin2 = - arrowRadius * Math.sin(angleArrowRight);

    dc.fillPolygon([
        [Math.round(x + cos0), Math.round(y + sin0)], 
        [Math.round(x + cos1), Math.round(y + sin1)],
        [Math.round(x + cos2), Math.round(y + sin2)]]);
  }

  function getFallbackWeatherBitmap(condition as String) as LazyBitmap {
    switch (condition) {
      case "light rain":
        return bitmaps.weatherRainLight;
      case "rain":
      case "hail":
        return bitmaps.weatherRain;
      case "thunder":
        return bitmaps.weatherThunder;
      case "snow":
        return bitmaps.weatherSnow;
      case "fog":
        return bitmaps.weatherFog;
      default:
        return bitmaps.weatherCloud;
    }
  }

  function drawActivityCount(dc as Dc) {
    var x = 132;
    var y = 118;

    var daily = self.models.dayModel.activityCount;

    if (daily > 0) {
      dc.drawBitmap(x, y, (daily == 1 ? bitmaps.star : bitmaps.stars).getBitmap());
    }
  }

  function drawSteps(dc as Dc) {
    var x = 114;
    var y = 130;

    var steps = self.models.minuteModel.steps;

    drawProgress(dc, x, y, steps.daily, steps.goal);
    if (steps.daily < steps.goal) {
      dc.drawBitmap(x - 8, y - 8, bitmaps.steps.getBitmap());
    }
  }

  function drawActiveMinutes(dc as Dc) {
    var x = 42;
    var y = 160;
    var width = 92;
    var height = 8;

    var minutes = self.models.minuteModel.activeMinutes;

    var value = minutes.weekly;
    var split = minutes.weekly - minutes.daily;
    var max = minutes.goal;
    var fullBars = Math.floor(value / max);
    value = value % max;
    split = split - (fullBars * max);
    if (split < 0) {
      split = 0;
    }

    dc.setPenWidth(2);

    var splitAsX = Utils.scaleValue(split, max, width);
    if (split > 0) {
      dc.drawBitmap(x, y, bitmaps.minutesLinearGrey.getBitmap());
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      dc.drawRectangle(x + 1, y, splitAsX - 1, height); // pixel adjustments compensate for 2px penwidth
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
      dc.fillRectangle(x + splitAsX, y, width - splitAsX, height);
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }
    var valueAsX = Utils.scaleValue(value, max, width);
    if (valueAsX > splitAsX) {
      dc.fillRectangle(x + splitAsX, y-1, valueAsX - splitAsX, height+1);
    }
    // Note the pixels overlap with minutesLinearGrey, allowing us to draw the background on top
    dc.drawBitmap(x, y-1, bitmaps.minutesLinearBackground.getBitmap());

    if (fullBars == 0) {
      var weekdayAsX = 1 + Utils.scaleValue(models.dayModel.weekday, 7, width - 2);
      dc.fillPolygon([
        [x+weekdayAsX, y-2],
        [x+weekdayAsX - 6, y-8],
        [x+weekdayAsX + 6, y-8]
      ]);
    } else {
      for (var i = 0; i < fullBars && i <= 10; i++) {
        dc.drawBitmap(x + i * 10, y-10, bitmaps.starTiny.getBitmap());
      }
    }
  }

  function drawRecoveryTime(dc as Dc) {
    var recoveryTime = self.models.minuteModel.recoveryTime;
    
    var x = 42;
    var y = 170;
    var width = 92;
    var height = 4;

    var max = 24;
    if (recoveryTime > 72) {
        max = 96;
    } else if (recoveryTime > 48) {
        max = 72;
    } else if (recoveryTime > 24) {
        max = 48;
    }

    var recoveryTimeAsWidth = Utils.scaleValue(recoveryTime, max, width);
    var barStartX = x + width - recoveryTimeAsWidth;

    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.fillRectangle(barStartX, y, recoveryTimeAsWidth, height);
    
    var segmentCount = max / 24;
    if (segmentCount > 1) {
      var segmentWidth = Utils.scaleValue(24, max, width);
      var separatorWidth = 3;
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);

      for (var i = 1; i < segmentCount; i++) {
        var separatorPosFromRight = i * segmentWidth;
        var separatorX = x + width - separatorPosFromRight - 1;
        
        if (separatorX > barStartX) {
          dc.fillRectangle(separatorX, y, separatorWidth, height);
        }
      }
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }
  }

  function drawProgress(dc as Dc, x as Number, y as Number, value as Number, max as Number) {
    var fullCircles = Math.floor(value / max);
    var radius = 6;
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

    value = value % max;
    var valueAsAngle = 90 - Utils.scaleValue(value, max, 360);
    if (valueAsAngle != 90) {
      dc.setPenWidth(14);
      dc.drawArc(x, y, radius, Graphics.ARC_CLOCKWISE, 90, valueAsAngle);
    }
    drawProgressComplete(dc, x, y, fullCircles);
  }

  function drawProgressComplete(dc as Dc, x as Number, y as Number, fullCircles as Number) {
    if (fullCircles > 0) {
      if (fullCircles == 1) {
        dc.drawBitmap(x - 10, y - 8, bitmaps.check.getBitmap());
      } else {
        dc.fillCircle(x, y, 8);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y - 12, Graphics.FONT_TINY, fullCircles, Graphics.TEXT_JUSTIFY_CENTER);
      }
    }
  }

  function drawTime(dc as Dc) {
    var clockTime = self.models.secondModel.clockTime;
    var timeString = Lang.format("$1$:$2$", [
      clockTime.hour,
      clockTime.min.format("%02d"),
    ]);
    dc.drawText(
      176 - 72,
      58,
      Graphics.FONT_NUMBER_THAI_HOT,
      timeString,
      Graphics.TEXT_JUSTIFY_RIGHT
    );
    drawSeconds(dc, false);
  }

  function drawAlarm(dc) {
    if (self.models.dayModel.alarm) {
      dc.drawBitmap(176-61, 73, bitmaps.alarm.getBitmap());
    }
  }

  function drawBattery(dc as Dc) {
    var x = 162;
    var y = 121;

    dc.drawBitmap(x, y, bitmaps.battery.getBitmap());
    var height = Utils.scaleValue(self.models.minuteModel.battery, 100, 10);
    dc.fillRectangle(x + 2, y + 4 + 10 - height, 5, height);
  }

  function drawPrecipitation(dc as Dc) {
    var x = 4;
    var y = 48;

    var precipitation = self.models.weatherModel.precipitation;
    if (precipitation != null && precipitation >= 80) {
      dc.drawBitmap(x, y, bitmaps.umbrella.getBitmap());
    }
  }

  function drawSunTime(dc as Dc) {
    var x = 17;
    var y = 40;
  
    dc.drawBitmap(x, y + 8, bitmaps.sunrise.getBitmap());
    dc.drawText(
      x + 19,
      y,
      Graphics.FONT_TINY,
      self.models.minuteModel.sunTime,
      Graphics.TEXT_JUSTIFY_LEFT
    );
  }

  function drawSeaTemperature(dc as Dc) as Boolean {
    var temperature = self.models.weatherModel.seaTemperature;
    if (temperature == null) {
      return false;
    }
    
    var x = 8;
    var y = 116;

    dc.drawBitmap(x, y + 2, bitmaps.waves.getBitmap());
    dc.drawText(x + 12 + 6, y - 6, Graphics.FONT_SMALL, temperature, Graphics.TEXT_JUSTIFY_LEFT);
    if (self.models.weatherModel.waveDirection != null) {
      drawWindBearing(dc, x + 8, y + 26, self.models.weatherModel.waveDirection);
    }
    dc.drawText(x + 21, y + 12, Graphics.FONT_TINY, self.models.weatherModel.waveHeight, Graphics.TEXT_JUSTIFY_LEFT);
    
    return true;
  }

  function drawAltitude(dc as Dc) {
    var x = 34;
    var y = 118;
    dc.drawBitmap(x, y, bitmaps.mountains.getBitmap());
    dc.drawText(x + 7, y + 10, Graphics.FONT_TINY, self.models.minuteModel.altitude, Graphics.TEXT_JUSTIFY_CENTER);
  }

  function drawBarometer(dc as Dc) {
    var x = 84;
    var y = 130;

    /* If close to the sea (where sea temperature is available), use absolute pressure. Altitude is often
    inaccurate so we're better off assuming it's close to zero.
    If we're far from the sea, eg in the mountains, sea level pressure is more useful on a barometer display. */
    var useSeaLevelPresure = (self.models.weatherModel.seaTemperature == null);
    var pressure = useSeaLevelPresure ? self.models.minuteModel.seaLevelPressure : 
                                        self.models.minuteModel.pressure;
    if (pressure == null) {
      return;
    }

    var r = 11.0;
    var rOpposite = 6.0;
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.fillCircle(x, y, r);

    // 3 deg/hPa, 1013.25 hPa is at 0 degrees. 
    var angleDeg = (pressure - 1013.25) * -3;
    var maxAngle = 170; // keep extremes just either side of 6 o'clock to avoid wraparound
    if (angleDeg > maxAngle) {
      angleDeg = maxAngle;
    } else if (angleDeg < -maxAngle) {
      angleDeg = -maxAngle;
    }
    var angleRad = Math.toRadians(angleDeg);

    // cos and sin are swapped and negated, fixes 90 degree rotation + inverted y axis
    var needleX = x - r * Math.sin(angleRad);
    var needleY = y - r * Math.cos(angleRad);

    // Thicker end is opposite
    var endRad = angleRad + Math.PI; // 180 degrees opposite
    var p1Rad = endRad - Math.PI / 6;
    var p2Rad = endRad + Math.PI / 6;

    var p1X = x - rOpposite * Math.sin(p1Rad);
    var p1Y = y - rOpposite * Math.cos(p1Rad);
    var p2X = x - rOpposite * Math.sin(p2Rad);
    var p2Y = y - rOpposite * Math.cos(p2Rad);

    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    dc.fillPolygon([
        [Math.round(needleX), Math.round(needleY)],
        [Math.round(p1X), Math.round(p1Y)],
        [Math.round(p2X), Math.round(p2Y)]
    ]);
  }


  function drawNotifications(dc as Dc) {
    var x = 154;
    var y = 94;
    var radius = 18;

    var notifications = self.models.secondModel.notificationCount;
    if (models.secondModel.doNotDisturb) {
      notifications = "-";
    } 

    if (models.secondModel.isPhoneConnected) {
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      dc.fillCircle(x, y, radius);
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    } else {
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
      dc.fillCircle(x, y, radius);
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      dc.setPenWidth(2);
      dc.drawCircle(x, y, radius);
    }
    dc.drawText(
      x,
      y - 2,
      Graphics.FONT_NUMBER_MILD,
      notifications,
      Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
    );
  }

  function drawPulse(dc as Dc) {
    // small box behind transparent text so text background
    // doesn't overlap heart or ring
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.fillRectangle(129, 32, 31, 20);

    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.drawText(
      113 + 31,
      26,
      Graphics.FONT_GLANCE_NUMBER,
      self.models.secondModel.heartRate,
      Graphics.TEXT_JUSTIFY_CENTER
    );
  }

  function drawSubScreen(dc as Dc) {    
    var subscreen = WatchUi.getSubscreen(); // 113,0  62x62
    var radius = subscreen.width / 2;

    var heart = getHeartBitmap();

    dc.drawBitmap(
      subscreen.x + 8,
      subscreen.y + 11, 
      heart.getBitmap()
    );

    drawPulse(dc);

    // Body battery
    var bodyBattery = self.models.minuteModel.bodyBattery;
    if (bodyBattery != null) {
      dc.setPenWidth(6);
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      if (bodyBattery == 100) {
        dc.drawCircle(subscreen.x + radius, subscreen.y + radius, radius - 3);
      } else {
        var valueAsDegrees = 90 - Utils.scaleValue(bodyBattery, 100, 360);
        dc.drawArc(
          subscreen.x + radius,
          subscreen.y + radius,
          radius - 3,
          Graphics.ARC_CLOCKWISE,
          90,
          valueAsDegrees
        );
      }
    }
  }

  function getHeartBitmap() as LazyBitmap {
    var stress = self.models.minuteModel.stress;
    if (stress == null) {
      return bitmaps.heart;
    }
    if (stress > 75) {
      return bitmaps.heartStressHigh;
    }
    if (stress > 50) {
      return bitmaps.heartStressMedium;
    }
    if (stress > 25) {
      return bitmaps.heartStressLow;
    }
    return bitmaps.heartRest;
  }

  // Called when this View is removed from the screen. Save the
  // state of this View here. This includes freeing resources from
  // memory.
  function onHide() as Void {}

  // The user has just looked at their watch. Timers and animations may be started here.
  function onExitSleep() as Void {
    isHighPowerMode = true;
  }

  // Terminate any active timers and prepare for slow updates.
  function onEnterSleep() as Void {
    isHighPowerMode = false;
  }
}
