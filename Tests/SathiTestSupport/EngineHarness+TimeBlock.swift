import Foundation
import SathiCore

extension EngineHarness {
    package static func quiet(
        at start: Date = day(2026, 3, 4, 10),
        configure: (inout Persisted) -> Void = { _ in }
    ) -> EngineHarness {
        EngineHarness(at: start) {
            $0.prefs.water.enabled = false
            $0.prefs.reading.enabled = false
            $0.prefs.meditation.enabled = false
            $0.prefs.gym.enabled = false
            configure(&$0)
        }
    }

    package static func restarted(from old: EngineHarness, at start: Date) -> EngineHarness {
        quiet(at: start) {
            $0.prefs = old.store.prefs
            $0.live = old.store.live
        }
    }

    @discardableResult
    package func startBlock(
        _ title: String = "Plan",
        _ length: TimeBlockLength = .minutes(30),
        calendar: String = "work"
    ) -> UUID {
        if case let .started(id) = engine.startBlock(title: title, length: length, calendarID: calendar) {
            return id
        }
        return UUID()
    }
}
