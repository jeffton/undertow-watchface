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

    function initialize() {
        self.weatherRepository = null;
        self.lastUpdateTime = new UpdateTime();
        self.dayModel = new DayModel(self.lastUpdateTime);
        self.dayModel.activityCount = 2;
        self.dayModel.date = "ONS 8";
        self.dayModel.alarm = true;
        self.dayModel.weekday = 3;

        self.tenMinuteModel = new TenMinuteModel(self.lastUpdateTime.today);
        self.tenMinuteModel.sunrise = "6:30";
        self.tenMinuteModel.sunriseTomorrow = "6:31";
        self.tenMinuteModel.sunset = "18:30";

        self.weatherModel = new WeatherModel();
        self.weatherModel.seaTemperature = "12°";
        self.weatherModel.temperature = "15°";
        self.weatherModel.windSpeed = "12";
        self.weatherModel.windDirection = 45;
        self.weatherModel.condition = "clear";
        self.weatherModel.waveHeight = "1.2";
        self.weatherModel.waveDirection = 60;
        self.weatherModel.cloudCover = 10;
        self.weatherModel.cloudCoverLow = 5;
        self.weatherModel.cloudCoverMedium = 8;
        self.weatherModel.cloudCoverHigh = 10;
        self.weatherModel.uvIndex = 3;
        self.weatherModel.precipitation = 85.3;

        self.sunModel = new SunModel();
        self.sunModel.minSunAzimuth = 80.0f;
        self.sunModel.maxSunAzimuth = 280.0f;
        self.sunModel.currentSunAzimuth = 140.0f;

        self.secondModel = new SecondModel(self.lastUpdateTime);
        // self.secondModel.seconds = "00";
        self.secondModel.heartRate = 69;
        self.secondModel.notificationCount = 2;
        self.secondModel.isPhoneConnected = true;
        self.secondModel.doNotDisturb = false;

        self.minuteModel = new MinuteModel(self.lastUpdateTime, self.tenMinuteModel);
        self.minuteModel.bodyBattery = 88;
        self.minuteModel.stress = 33;
        self.minuteModel.recoveryTime = 24;
        self.minuteModel.activeMinutes = new DailyWeekly(50, 150, 300);
        self.minuteModel.steps = new DailyWeekly(8000, 8000, 10000);
        self.minuteModel.battery = 88;
        self.minuteModel.sunTime = "18:30";
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
