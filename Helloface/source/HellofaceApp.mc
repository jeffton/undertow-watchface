import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

(:background)
class HellofaceApp extends Application.AppBase {
  var view as HellofaceView?;

  function initialize() {
    AppBase.initialize();
    Background.registerForActivityCompletedEvent();
  }

  public function getServiceDelegate() as [System.ServiceDelegate] {
    return [new HellofaceBackgroundDelegate()];
  }

  function onBackgroundData(data) {
    if (data instanceof Dictionary) {
      if (self.view != null) {
        self.view.onSeaDataUpdated(data);
      }
    }
  }

  // onStart() is called on application start up
  function onStart(state as Dictionary?) as Void {}

  // onStop() is called when your application is exiting
  function onStop(state as Dictionary?) as Void {}

  // Return the initial view of your application here
  function getInitialView() as [Views] or [Views, InputDelegates] {
    if (self.view == null) {
      self.view = new HellofaceView();
    }
    return [self.view];
  }
}

function getApp() as HellofaceApp {
  return Application.getApp() as HellofaceApp;
}
