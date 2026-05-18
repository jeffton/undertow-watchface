import Toybox.Time;
import Toybox.Lang;
class ModelsRepository {
    var lastUpdateTime as UpdateTime;
    var dayModel as DayModel;
    var tenMinuteModel as TenMinuteModel;
    var weatherRepository as WeatherRepository;
    var weatherModel as WeatherModel;
    var sunModel as SunModel?;
    var minuteModel as MinuteModel;
    var secondModel as SecondModel;

    function initialize() {
        self.lastUpdateTime = new UpdateTime();
        self.dayModel = new DayModel(lastUpdateTime);
        self.weatherRepository = new WeatherRepository();
        var location = self.weatherRepository.getLocation();
        self.tenMinuteModel = new TenMinuteModel(lastUpdateTime.today, location);
        self.weatherRepository.update();
        self.weatherModel = self.weatherRepository.getWeatherModel();
        self.sunModel = SunFactory.createSunModel(self.tenMinuteModel, location);
        self.secondModel = new SecondModel(lastUpdateTime);
        self.minuteModel = new MinuteModel(lastUpdateTime, self.tenMinuteModel);
    }

    function onWeatherUpdated(data as Dictionary) as Void {
        self.weatherRepository.onWeatherUpdated(data);
        var location = self.weatherRepository.getLocation();
        self.weatherModel = self.weatherRepository.getWeatherModel();
        self.tenMinuteModel = new TenMinuteModel(lastUpdateTime.today, location);
        self.sunModel = SunFactory.createSunModel(self.tenMinuteModel, location);
        self.minuteModel = new MinuteModel(lastUpdateTime, self.tenMinuteModel);
    }

    function updateModels() as Boolean {
        var updateTime = new UpdateTime();
        var diff = updateTime.compare(lastUpdateTime);
        lastUpdateTime = updateTime;

        switch (diff) {
        case UpdateTime.DAY:
            self.dayModel = new DayModel(updateTime);
        case UpdateTime.TEN_MINUTES:
            var location = self.weatherRepository.getLocation();
            self.tenMinuteModel = new TenMinuteModel(lastUpdateTime.today, location);
            self.weatherRepository.update();
            self.weatherModel = self.weatherRepository.getWeatherModel();
            self.sunModel = SunFactory.createSunModel(self.tenMinuteModel, location);
        case UpdateTime.MINUTE:
            self.minuteModel = new MinuteModel(updateTime, self.tenMinuteModel);
        case UpdateTime.SECOND:
            self.secondModel = new SecondModel(updateTime);
            return true;
        default:
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
}
