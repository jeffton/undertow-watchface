import Toybox.Lang;
import Toybox.Test;

(:test)
function wakeSyncContract(logger as Test.Logger) as Boolean {
  var service = new WakeSyncService();
  var sleeping = service.buildBody(1770000000, false);
  var awake = service.buildBody(1770000000, true);
  Test.assertEqual(sleeping["awake"], 0);
  Test.assertEqual(awake["awake"], 1);
  var bodies = [sleeping, awake];
  for (var i = 0; i < bodies.size(); i++) {
    var body = bodies[i];
    Test.assertEqual(body["format"], "compact");
    Test.assertEqual(body["lastWorkout"], 1770000000);
  }
  return true;
}
