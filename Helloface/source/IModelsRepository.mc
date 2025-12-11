import Toybox.Lang;
import Toybox.Time;

typedef IModelsRepository as interface {
    var lastUpdateTime as UpdateTime;
    var dayModel as DayModel;
    var tenMinuteModel as TenMinuteModel;
    var weatherRepository as WeatherRepository?;
    var weatherModel as WeatherModel;
    var sunRepository as SunRepository?;
    var sunModel as SunModel?;
    var minuteModel as MinuteModel;
    var secondModel as SecondModel;

    function onWeatherUpdated(data as Dictionary) as Void;
    function updateModels() as Boolean;
    function updateModelsPartial() as Boolean;
};
