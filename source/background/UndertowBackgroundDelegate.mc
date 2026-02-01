import Toybox.Position;
import Toybox.Time;
import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.Application;
import Toybox.Application.Storage;


(:background)
class UndertowBackgroundDelegate extends Toybox.System.ServiceDelegate {

  function initialize() {
    ServiceDelegate.initialize();
  }

  function onTemporalEvent() {
    new WeatherService().onTemporalEvent();
  }

  function onActivityCompleted(activity as {
    :sport as $.Toybox.Activity.Sport,
    :subSport as $.Toybox.Activity.SubSport
    }) as Void {
      new WeatherService().onActivityCompleted(activity);
  }
}