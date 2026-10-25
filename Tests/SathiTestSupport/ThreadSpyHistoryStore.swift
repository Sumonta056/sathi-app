import Foundation
import SathiCore

package final class ThreadSpyHistoryStore: HistoryStore, @unchecked Sendable {
    private let lock = NSLock()
    private let events: [HistoryEvent]
    private var mainThreadFlags: [Bool] = []

    package init(events: [HistoryEvent] = []) {
        self.events = events
    }

    package var allEventsOnMain: [Bool] {
        lock.lock()
        defer { lock.unlock() }
        return mainThreadFlags
    }

    package func append(_ event: HistoryEvent) {}

    package func events(from start: Date, to end: Date) -> [HistoryEvent] {
        events.filter { $0.date >= start && $0.date < end }
    }

    package func allEvents() -> [HistoryEvent] {
        let onMain = Thread.isMainThread
        lock.lock()
        mainThreadFlags.append(onMain)
        lock.unlock()
        return events
    }

    @discardableResult
    package func flush() -> Bool { true }
}
