import Toybox.Time;
import Toybox.Lang;

class ModelsRepository {
    var lastUpdateTime as UpdateTime;
    var dayModel as DayModel;
    var tenMinuteModel as TenMinuteModel;
    var weatherRepository as WeatherRepository;
    var weatherModel as WeatherModel;
    var sunRepository as SunRepository;
    var sunModel as SunModel?;
    var minuteModel as MinuteModel;
    var secondModel as SecondModel;

    function initialize() {
        self.lastUpdateTime = new UpdateTime();
        self.dayModel = new DayModel(lastUpdateTime);
        self.tenMinuteModel = new TenMinuteModel(lastUpdateTime.today);
        self.weatherRepository = new WeatherRepository();
        self.weatherRepository.update();
        self.weatherModel = self.weatherRepository.getWeatherModel();
        self.sunRepository = new SunRepository();
        self.sunModel = self.sunRepository.getSunModel(self.tenMinuteModel);
        self.secondModel = new SecondModel(lastUpdateTime);
        self.minuteModel = new MinuteModel(lastUpdateTime, tenMinuteModel);
    }

    function onWeatherUpdated(data as Dictionary) {
        self.weatherRepository.onWeatherUpdated(data);
        self.weatherModel = self.weatherRepository.getWeatherModel();
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
            self.sunModel = self.sunRepository.getSunModel(self.tenMinuteModel);
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
}
