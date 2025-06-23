import Toybox.Lang;
import Toybox.WatchUi;

class LazyBitmap {
  var resourceId as ResourceId;
  var bitmap as BitmapResource?;

  function initialize(resourceId as ResourceId) {
    self.resourceId = resourceId;
  }

  function getBitmap() as BitmapResource {
    if (self.bitmap == null) {
      self.bitmap = WatchUi.loadResource(resourceId);
    }
    return self.bitmap;
  }
}