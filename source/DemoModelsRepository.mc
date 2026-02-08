import Toybox.Time;
import Toybox.Lang;
import Toybox.System;

(:debug)
class DemoModelsRepository {
    var lastUpdateTime as UpdateTime;
    var dayModel as DayModel;
    var tenMinuteModel as TenMinuteModel;
    var weatherRepository as WeatherRepository?;
    var weatherModel as WeatherModel;
    var sunModel as SunModel?;
    var minuteModel as MinuteModel;
    var secondModel as SecondModel;
    var demoHour as Number;
    var demoMinute as Number;
    var demoSecond as Number;

    function initialize() {
        self.weatherRepository = null;
        self.demoHour = 10;
        self.demoMinute = 10;
        self.demoSecond = 42;
        self.lastUpdateTime = new UpdateTime();
        self.lastUpdateTime.clockTime.hour = self.demoHour;
        self.lastUpdateTime.clockTime.min = self.demoMinute;
        self.lastUpdateTime.clockTime.sec = self.demoSecond;
        self.dayModel = new DayModel(self.lastUpdateTime);
        self.dayModel.hasWorkoutToday = true;
        self.dayModel.date = "MÅN 14";
        self.dayModel.alarm = true;
        self.dayModel.weekday = 3;

        self.tenMinuteModel = new TenMinuteModel(self.lastUpdateTime.today);
        self.tenMinuteModel.sunrise = "6:01";
        self.tenMinuteModel.sunriseTomorrow = "6:02";
        self.tenMinuteModel.sunset = "20:03";
        self.tenMinuteModel.sunsetTomorrow = "20:04";

        self.weatherModel = new WeatherModel();
        self.weatherModel.seaTemperature = "14°";
        self.weatherModel.temperature = "20°";
        self.weatherModel.windSpeed = "5";
        self.weatherModel.windDirection = 20;
        self.weatherModel.condition = "partly cloudy 40";
        self.weatherModel.waveHeight = "0.3";
        self.weatherModel.waveDirection = 60;
        self.weatherModel.uvIndex = 3;
        self.weatherModel.precipitation = 88;

        self.sunModel = new SunModel();
        self.sunModel.minSunAzimuth = 75.0f;
        self.sunModel.maxSunAzimuth = 285.0f;
        self.sunModel.currentSunAzimuth = 137.0f;

        self.secondModel = new SecondModel(self.lastUpdateTime);
        self.secondModel.heartRate = 67;
        self.secondModel.notificationCount = 2;
        self.secondModel.isPhoneConnected = true;
        self.secondModel.doNotDisturb = false;

        self.minuteModel = new MinuteModel(self.lastUpdateTime, self.tenMinuteModel);
        self.minuteModel.bodyBattery = 88;
        self.minuteModel.stress = 33;
        self.minuteModel.recoveryTime = 17;
        self.minuteModel.activeMinutes = new DailyWeekly(50, 150, 300);
        self.minuteModel.steps = new DailyWeekly(8000, 8000, 10000);
        self.minuteModel.battery = 88;
        self.minuteModel.sunTimes = ["20:03", "6:02"];
        self.minuteModel.altitude = "2200m";
        self.minuteModel.pressure = 1030.0;
        self.minuteModel.seaLevelPressure = 1030.0;
    }

    function onWeatherUpdated(data as Dictionary) as Void {}

    function updateModels() as Boolean {
        return false;
    }
    
    function updateModelsPartial() as Boolean {
        return false;
    }
}
