import Toybox.Application.Storage;
import Toybox.Time;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.Time.Gregorian;

class PressureRepository {
    private var cachedData as Dictionary?;

    function initialize() {
        cachedData = Storage.getValue("pressure") as Dictionary?;
    }

    function getPressureChangeOnInit() as Float? {
        var now = Time.now();
        var needsUpdate = true;

        if (cachedData != null) {
            var calculatedAt = cachedData.get("calculatedAt") as Number?;
            if (calculatedAt != null) {
                var tenMinutes = new Time.Duration(600);
                var age = now.subtract(new Time.Moment(calculatedAt));
                if (age.value() < tenMinutes.value()) {
                    needsUpdate = false;
                }
            }
        }
        
        if (needsUpdate) {
            return updateAndGetPressureChange();
        }
        
        if (cachedData != null) {
            return cachedData.get("pressureChange") as Float?;
        }
        return null;
    }

    function updateAndGetPressureChange() as Float? {
        var now = Time.now();
        var newPressureChange = calculatePressureChange(now);

        if (newPressureChange != null) {
            cachedData = {
                "pressureChange" => newPressureChange,
                "calculatedAt" => now.value()
            };
            Storage.setValue("pressure", cachedData);
        }
        
        if (cachedData != null) {
            return cachedData.get("pressureChange") as Float?;
        }
        return null;
    }

    private function calculatePressureChange(now as Moment) as Float? {
        var oneHour = new Time.Duration(Gregorian.SECONDS_PER_HOUR);
        var pressureIterator = SensorHistory.getPressureHistory({
            :period => oneHour,
        });

        // We will compare the first 10 minutes of the hour period with the last 10 minutes.
        var startOfLast10Mins = now.subtract(new Time.Duration(600)); // 10 minutes ago
        var endOfFirst10Mins = now.subtract(new Time.Duration(3000)); // 50 mins ago

        var firstIntervalSum = 0.0f;
        var firstIntervalCount = 0;
        var lastIntervalSum = 0.0f;
        var lastIntervalCount = 0;

        var sample = pressureIterator.next();
        while (sample != null) {
            if (sample.data != null) {
                if (sample.when.greaterThan(startOfLast10Mins)) {
                    lastIntervalSum += sample.data;
                    lastIntervalCount++;
                } else if (sample.when.lessThan(endOfFirst10Mins)) {
                    firstIntervalSum += sample.data;
                    firstIntervalCount++;
                }
            }
            sample = pressureIterator.next();
        }

        if (firstIntervalCount > 0 && lastIntervalCount > 0) {
            var firstIntervalAvg = firstIntervalSum / firstIntervalCount;
            var lastIntervalAvg = lastIntervalSum / lastIntervalCount;
            // convert from Pa to hPa
            return (lastIntervalAvg - firstIntervalAvg) / 100.0;
        }
        return null;
    }
} 