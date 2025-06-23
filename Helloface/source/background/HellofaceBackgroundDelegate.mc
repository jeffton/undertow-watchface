import Toybox.Position;
import Toybox.Time;
import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.Application;
import Toybox.Application.Storage;


(:background)
class HellofaceBackgroundDelegate extends Toybox.System.ServiceDelegate {

  function initialize() {
    ServiceDelegate.initialize();
  }

  function onTemporalEvent() {
    new SeaTemperatureService().onTemporalEvent();
  }

  function onActivityCompleted(activity as {
    :sport as $.Toybox.Activity.Sport,
    :subSport as $.Toybox.Activity.SubSport
    }) as Void {
      new ActivityCountService().onActivityCompleted(activity);
  }
}