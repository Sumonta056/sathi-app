import Foundation
import SathiCore

extension EngineHarness {
    package static func tracker(
        at start: Date = day(2026, 3, 4, 10),
        activities: [Activity] = [],
        configure: (inout Persisted) -> Void = { _ in }
    ) -> EngineHarness {
        EngineHarness(at: start, activities: InMemoryActivityStore(activities: activities)) {
            $0.prefs.water.enabled = false
            $0.prefs.reading.enabled = false
            $0.prefs.meditation.enabled = false
            $0.prefs.gym.enabled = false
            $0.prefs.tracker.isOn = true
            configure(&$0)
        }
    }

    package static func restartedTracker(from old: EngineHarness, at start: Date) -> EngineHarness {
        EngineHarness(at: start, activities: old.activities) {
            $0.prefs = old.store.prefs
            $0.live = old.store.live
        }
    }

    package var tracker: TrackerLiveState { store.live.tracker }
    package var running: RunningActivity? { engine.runningActivity }
}
