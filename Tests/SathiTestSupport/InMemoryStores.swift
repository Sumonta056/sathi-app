import Foundation
import SathiCore

package final class InMemoryStateStore: StateStore {
    package var prefs: Prefs
    package var live: LiveState
    package private(set) var prefsSaves = 0
    package private(set) var liveSaves = 0
    package private(set) var flushes = 0
    package var failFlush = false

    package init(prefs: Prefs = Prefs(), live: LiveState = LiveState()) {
        self.prefs = prefs
        self.live = live
    }

    package func loadPrefs() -> Prefs { prefs }

    package func savePrefs(_ prefs: Prefs) {
        self.prefs = prefs
        prefsSaves += 1
    }

    package func loadLive() -> LiveState { live }

    package func saveLive(_ live: LiveState) {
        self.live = live
        liveSaves += 1
    }

    @discardableResult
    package func flush() -> Bool {
        flushes += 1
        return !failFlush
    }
}

package final class InMemoryHistoryStore: HistoryStore {
    package private(set) var events: [HistoryEvent]
    package private(set) var appended: [HistoryEvent] = []
    package private(set) var ranges: [DateInterval] = []
    package private(set) var allEventsCalls = 0
    package private(set) var flushes = 0
    package var failFlush = false

    package init(events: [HistoryEvent] = []) {
        self.events = events
    }

    package func append(_ event: HistoryEvent) {
        events.append(event)
        appended.append(event)
    }

    package func events(from start: Date, to end: Date) -> [HistoryEvent] {
        ranges.append(DateInterval(start: start, end: max(start, end)))
        return events.filter { $0.date >= start && $0.date < end }.sorted { $0.date < $1.date }
    }

    package func allEvents() -> [HistoryEvent] {
        allEventsCalls += 1
        return events.sorted { $0.date < $1.date }
    }

    package func clearRanges() {
        ranges.removeAll()
    }

    @discardableResult
    package func flush() -> Bool {
        flushes += 1
        return !failFlush
    }
}
