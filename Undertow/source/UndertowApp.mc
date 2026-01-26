import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

(:background)
class UndertowApp extends Application.AppBase {
  var view as UndertowView?;

  function initialize() {
    AppBase.initialize();
    Background.registerForActivityCompletedEvent();
  }

  public function getServiceDelegate() as [System.ServiceDelegate] {
    return [new UndertowBackgroundDelegate()];
  }

  function onBackgroundData(data) {
    if (data instanceof Dictionary && data.hasKey("forecast")) {
      Storage.setValue("weather", data);
      if (self.view != null) {
        self.view.onWeatherUpdated(data);
      }
    }
  }

  // Return the initial view of your application here
  function getInitialView() as [Views] or [Views, InputDelegates] {
    if (self.view == null) {
      self.view = new UndertowView();
    }
    return [self.view];
  }
}

function getApp() as UndertowApp {
  return Application.getApp() as UndertowApp;
}
