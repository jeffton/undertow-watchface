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
  
  var lastUpdateTime as UpdateTime;
  var dayModel as DayModel;
  var tenMinuteModel as TenMinuteModel;
  var weatherRepository as WeatherRepository;
  var weatherModel as WeatherModel;
  var minuteModel as MinuteModel;
  var secondModel as SecondModel;

  var previousSecond as SecondModel?;

  var heartBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.heart);
  var heartRestBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.heartRest);
  var heartStressLowBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.heartStressLow);
  var heartStressMediumBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.heartStressMedium);
  var heartStressHighBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.heartStressHigh);

  var stepsBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.steps);
  var starBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.star);
  var starsBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.stars);

  var sunriseBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.sunrise);
  var alarmBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.alarm);
  var batteryBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.battery);
  var minutesBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.minutes);
  var minutesLinearGreyBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.minutesLinearGrey);
  var checkBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.check);

  var weatherSunBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.weatherSun);
  var weatherMoonBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.weatherMoon);
  var weatherCloudBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.weatherCloud);
  var weatherCloud25Bitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.weatherCloud25);
  var weatherCloud50Bitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.weatherCloud50);
  var weatherCloud75Bitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.weatherCloud75);
  var weatherRainBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.weatherRain);
  var weatherRainLightBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.weatherRainLight);
  var weatherThunderBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.weatherThunder);
  var weatherSnowBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.weatherSnow);
  var weatherFogBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.weatherFog);
  var wavesBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.waves);
  var mountainsBitmap as LazyBitmap = new LazyBitmap(Rez.Drawables.mountains);

  var isHighPowerMode = true;

  function initialize() {
    WatchFace.initialize();

    self.lastUpdateTime = new UpdateTime();
    self.dayModel = new DayModel(lastUpdateTime);
    self.tenMinuteModel = new TenMinuteModel(lastUpdateTime.today);
    self.weatherRepository = new WeatherRepository();
    self.weatherRepository.update();
    self.weatherModel = self.weatherRepository.getWeatherModel();
    self.secondModel = new SecondModel(lastUpdateTime);
    self.minuteModel = new MinuteModel(lastUpdateTime, tenMinuteModel);
  }

  function onWeatherUpdated(data as Dictionary) {
    self.weatherRepository.onWeatherUpdated(data);
    self.weatherModel = self.weatherRepository.getWeatherModel();
    WatchUi.requestUpdate();
  }

  // Load your resources here
  function onLayout(dc as Dc) as Void {}

  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() as Void {
  }

  function updateModels() as Boolean {
    var updateTime = new UpdateTime();
    var diff = updateTime.compare(lastUpdateTime);
    lastUpdateTime = updateTime;

    switch (diff) {
      // Cases intentionally fall through
      case UpdateTime.DAY:
        self.dayModel = new DayModel(updateTime);
      case UpdateTime.TEN_MINUTES:
        self.tenMinuteModel = new TenMinuteModel(lastUpdateTime.today);
        self.weatherRepository.update();
        self.weatherModel = self.weatherRepository.getWeatherModel();
      case UpdateTime.MINUTE:
        self.minuteModel = new MinuteModel(updateTime, self.tenMinuteModel);
      case UpdateTime.SECOND:
        self.secondModel = new SecondModel(updateTime);
        return true;
      default: // that's case EQUAL
        return false;
    }
  }

  function updateModelsPartial() as Boolean {
    var updateTime = new UpdateTime();
    var diff = updateTime.compareSeconds(lastUpdateTime);
    lastUpdateTime = updateTime;

    if (diff == UpdateTime.SECOND) {
      self.secondModel = new SecondModel(updateTime);
      return true;
    } else {
      return false;
    }
  }

  // Update the view
  function onUpdate(dc as Dc) as Void {
    updateModels();

    dc.setClip(0, 0, 176, 176);

    drawMainScreen(dc);
    drawSubScreen(dc);

    previousSecond = secondModel;
  }

  function onPartialUpdate(dc as Graphics.Dc) as Void {
    if (!updateModelsPartial()) {
      return;
    }

    var diff = self.secondModel.compare(previousSecond);
    previousSecond = self.secondModel;
    
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
      self.secondModel.seconds,
      Graphics.TEXT_JUSTIFY_LEFT
    );
  }

  function drawMainScreen(dc as Dc) {
    // Background
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.fillRectangle(0, 0, 176, 176);

    var isDaytime = self.tenMinuteModel.isDaytime(Time.now());

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
      self.dayModel.date,
      Graphics.TEXT_JUSTIFY_CENTER
    );
  }

  function drawWeather(dc as Dc, isDaytime as Boolean) {
    drawWeatherCondition(dc, isDaytime);

    dc.drawText(
      30,
      20,
      Graphics.FONT_GLANCE,
      self.weatherModel.temperature,
      Graphics.TEXT_JUSTIFY_LEFT
    );

    dc.drawText(
      80,
      20,
      Graphics.FONT_GLANCE,
      self.weatherModel.windSpeed,
      Graphics.TEXT_JUSTIFY_LEFT
    );

    if (self.weatherModel.windDirection != null) {
      drawWindBearing(dc, 68, 33, self.weatherModel.windDirection);
    }
  }

  function drawWeatherCondition(dc as Dc, isDaytime as Boolean) {
    var x = 10;
    var y = 24;

    if (self.weatherModel.condition != null) {
      var condition = self.weatherModel.condition as String;

      if (
        condition.equals("clear") ||
        condition.equals("fair") ||
        condition.equals("partly cloudy") ||
        condition.equals("cloudy")
      ) {
        var cloudCover = self.weatherModel.cloudCover as Number;
        if (cloudCover < 80) {
          // Draw sun or moon
          var baseBitmap = isDaytime ? weatherSunBitmap : weatherMoonBitmap;
          dc.drawBitmap(x, y, baseBitmap.getBitmap());
        }

        // Draw cloud overlay
        if (cloudCover >= 80) {
          dc.drawBitmap(x, y, weatherCloudBitmap.getBitmap());
        } else if (cloudCover >= 60) {
          dc.drawBitmap(x, y, weatherCloud75Bitmap.getBitmap());
        } else if (cloudCover >= 40) {
          dc.drawBitmap(x, y, weatherCloud50Bitmap.getBitmap());
        } else if (cloudCover >= 20) {
          dc.drawBitmap(x, y, weatherCloud25Bitmap.getBitmap());
        }
      } else {
        var bitmap = getFallbackWeatherBitmap(condition);
        dc.drawBitmap(x, y, bitmap.getBitmap());
      }
    }
  }

  function drawWindBearing(dc as Dc, x, y, angle) {
    angle = -angle - 90; // wind bearing is 0 = North and clockwise, also it's actually direction so we flip it 180 (-90 instead of +90)
    var radians = angle * Math.PI / 180.0;
    var radius = 8;
    var cos = (radius - 3) * Math.cos(radians);
    var sin = - (radius - 3) * Math.sin(radians); // y axis is inverted
    var cos0 = radius * Math.cos(radians);
    var sin0 = - radius * Math.sin(radians); // y axis is inverted
    dc.setPenWidth(3);
    dc.drawLine(x - cos0, y - sin0, x + cos, y + sin);

    var angleArrowLeft = radians - 1.5;
    var angleArrowRight = radians + 1.5;
    var arrowRadius = 4;

    var cos1 = arrowRadius * Math.cos(angleArrowLeft);
    var cos2 = arrowRadius * Math.cos(angleArrowRight);
    var sin1 = - arrowRadius * Math.sin(angleArrowLeft);
    var sin2 = - arrowRadius * Math.sin(angleArrowRight);

    dc.fillPolygon([
        [x + cos0, y + sin0], 
        [x + cos1, y + sin1],
        [x + cos2, y + sin2]]);
  }

  function getFallbackWeatherBitmap(condition as String) as LazyBitmap {
    switch (condition) {
      case "light rain":
        return weatherRainLightBitmap;
      case "rain":
      case "hail":
        return weatherRainBitmap;
      case "thunder":
        return weatherThunderBitmap;
      case "snow":
        return weatherSnowBitmap;
      case "fog":
        return weatherFogBitmap;
      default:
        return weatherCloudBitmap;
    }
  }

  function drawActivityCount(dc as Dc) {
    var x = 135;
    var y = 117;

    var daily = self.dayModel.activityCount;

    if (daily > 0) {
      dc.drawBitmap(x, y, (daily == 1 ? starBitmap : starsBitmap).getBitmap());
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
      dc.drawText(x + 14, y + 2, Graphics.FONT_TINY, daily, Graphics.TEXT_JUSTIFY_CENTER);
    }
  }

  function drawSteps(dc as Dc) {
    var x = 124;
    var y = 158;

    var steps = self.minuteModel.steps;

    drawProgress(dc, x, y, steps.daily, steps.goal);
    if (steps.daily < steps.goal) {
      dc.drawBitmap(x - 8, y - 8, stepsBitmap.getBitmap());
    }
  }

  function drawActiveMinutes(dc as Dc) {
    var x = 36;
    var y = 120;
    var width = 91;
    var height = 8;

    var minutes = new DailyWeekly(100, 300, 400); //self.minuteModel.activeMinutes;

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

    var splitAsX = split * width / max;
    if (split > 0) {
      dc.drawBitmap(x, y, minutesLinearGreyBitmap.getBitmap());
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      dc.drawRectangle(x, y, splitAsX, height);
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
      dc.fillRectangle(x + splitAsX, y, width - splitAsX, height);
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }
    var valueAsX = value * width / max;
    if (valueAsX > splitAsX) {
      dc.fillRectangle(x + splitAsX, y-1, valueAsX - splitAsX, height+1);
    }

    for (var i = 0; i <= 7; i++) {
      var weekdayAsX = i * width / 7;
      if (weekdayAsX >= valueAsX) {
        dc.drawLine(x+weekdayAsX, y+2, x+weekdayAsX, y+height-2);
      }
      if (i == dayModel.weekday && fullBars == 0) {
        dc.fillPolygon([
          [x+weekdayAsX, y-2],
          [x+weekdayAsX - 4, y-7],
          [x+weekdayAsX + 4, y-7]
        ]);
      }
    }

    if (fullBars == 0) {
      dc.drawBitmap(x-25, y-4, minutesBitmap.getBitmap());
    } else {
      drawProgressComplete(dc, x-19 ,y+3, fullBars);
    }
  }

  function drawRecoveryTime(dc as Dc) {
    var recoveryTime = self.minuteModel.recoveryTime;
    
    var x = 35;
    var y = 130;
    var width = 93;
    var height = 4;

    var max = 24;
    if (recoveryTime > 72) {
        max = 96;
    } else if (recoveryTime > 48) {
        max = 72;
    } else if (recoveryTime > 24) {
        max = 48;
    }

    var recoveryTimeAsWidth = recoveryTime * width / max;
    var barStartX = x + width - recoveryTimeAsWidth;

    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.fillRectangle(barStartX, y, recoveryTimeAsWidth, height);
    
    var segmentCount = max / 24;
    if (segmentCount > 1) {
        var segmentWidth = 24 * width / max;
        var separatorWidth = 2;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);

        for (var i = 1; i < segmentCount; i++) {
            var separatorPosFromRight = i * segmentWidth;
            var separatorX = x + width - separatorPosFromRight - 1;
            
            if (separatorX > barStartX) {
                 dc.fillRectangle(separatorX, y, separatorWidth, height);
            }
        }
    }
  }

  function drawProgress(dc as Dc, x as Number, y as Number, value as Number, max as Number) {
    var fullCircles = Math.floor(value / max);
    var radius = 7;
    value = value % max;
    var valueAsAngle = 90 - (value * 360 / max);
    if (valueAsAngle != 90) {
      dc.setPenWidth(15);
      dc.drawArc(x, y, radius, Graphics.ARC_CLOCKWISE, 90, valueAsAngle);
    }
    drawProgressComplete(dc, x, y, fullCircles);
  }

  function drawProgressComplete(dc as Dc, x as Number, y as Number, fullCircles as Number) {
    if (fullCircles > 0) {
      if (fullCircles == 1) {
        dc.drawBitmap(x - 10, y - 8, checkBitmap.getBitmap());
      } else {
        dc.fillCircle(x, y, 8);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y - 12, Graphics.FONT_TINY, fullCircles, Graphics.TEXT_JUSTIFY_CENTER);
      }
    }
  }

  function drawTime(dc as Dc) {
    var clockTime = self.secondModel.clockTime;
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
    if (self.dayModel.alarm) {
      dc.drawBitmap(176-61, 73, alarmBitmap.getBitmap());
    }
  }

  function drawBattery(dc as Dc) {
    var x = 80;
    var y = 49;

    dc.drawBitmap(x, y, batteryBitmap.getBitmap());
    var width = Math.round(self.minuteModel.battery / 10.0);
    dc.fillRectangle(x + 2, y + 2, width, 5);
  }

  function drawSunTime(dc as Dc) {
    var x = 10;
    var y = 40;
  
    dc.drawBitmap(x, y + 8, sunriseBitmap.getBitmap());
    dc.drawText(
      x + 19,
      y,
      Graphics.FONT_TINY,
      self.minuteModel.sunTime,
      Graphics.TEXT_JUSTIFY_LEFT
    );
  }

  function drawSeaTemperature(dc as Dc) as Boolean {
    var temperature = self.weatherModel.seaTemperature;
    if (temperature == null) {
      return false;
    }
    
    var x = 40;
    var y = 132;

    dc.drawText(x, y, Graphics.FONT_SMALL, temperature, Graphics.TEXT_JUSTIFY_CENTER);
    dc.drawBitmap(x - 6, y + 25, wavesBitmap.getBitmap());
    if (self.weatherModel.waveHeight != null) {
      dc.drawText(x + 12, y + 25, Graphics.FONT_TINY, self.weatherModel.waveHeight, Graphics.TEXT_JUSTIFY_LEFT);
    }
    return true;
  }

  function drawAltitude(dc as Dc) {
    var x = 18;
    var y = 140;
    dc.drawBitmap(x, y, mountainsBitmap.getBitmap());
    dc.drawText(x + 17, y - 6, Graphics.FONT_TINY, self.minuteModel.altitude, Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(x + 17, y + 12, Graphics.FONT_TINY, self.minuteModel.pressure, Graphics.TEXT_JUSTIFY_LEFT);
  }

  function drawNotifications(dc as Dc) {
    var x = 154;
    var y = 94;
    var radius = 18;

    var notifications = self.secondModel.notificationCount;
    if (secondModel.doNotDisturb) {
      notifications = "-";
    } 

    if (secondModel.isPhoneConnected) {
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
      self.secondModel.heartRate,
      Graphics.TEXT_JUSTIFY_CENTER
    );
  }

  function drawSubScreen(dc as Dc) {    
    var subscreen = WatchUi.getSubscreen(); // 113,0  62x62
    var radius = subscreen.width / 2;
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

    // Stress. Heart is 22w x 17h. 3 pixels from bottom, 2 from top are edges.
    // 16 pixels height in heart to fill. Just filling 15 because magic.
    var stress = self.minuteModel.stress;
    var rest = stress == null ? 100 : (100 - stress);
    var heartFill = (rest * 15) / 100;

    dc.fillRectangle(
      subscreen.x + 31 - 11,
      subscreen.y + 11 + 2 + 15 - heartFill,
      22,
      heartFill
    );

    var heart = getHeartBitmap();

    dc.drawBitmap(
      subscreen.x + 8,
      subscreen.y + 11, 
      heart.getBitmap()
    );

    drawPulse(dc);

    // Body battery

    var bodyBattery = self.minuteModel.bodyBattery;
    if (bodyBattery != null) {
      dc.setPenWidth(6);
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      if (bodyBattery == 100) {
        dc.drawCircle(subscreen.x + radius, subscreen.y + radius, radius - 3);
      } else {
        var valueAsDegrees = 90 - (bodyBattery * 360 / 100);
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
    var stress = self.minuteModel.stress;
    if (stress == null) {
      return heartBitmap;
    }
    if (stress > 75) {
      return heartStressHighBitmap;
    }
    if (stress > 50) {
      return heartStressMediumBitmap;
    }
    if (stress > 25) {
      return heartStressLowBitmap;
    }
    return heartRestBitmap;
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
