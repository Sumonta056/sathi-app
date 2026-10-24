import Foundation

package final class FileHistoryStore: HistoryStore, @unchecked Sendable {
    private let folder: URL
    private let calendar: Calendar
    private let delay: TimeInterval
    private let queue = DispatchQueue(label: "sathi.history-store")
    private var cache: [String: [HistoryEvent]] = [:]
    private var dirty: Set<String> = []
    private var blocked: Set<String> = []
    private var currentMonth: String?
    private var isScheduled = false

    package init(base: URL, calendar: Calendar, delay: TimeInterval = Timing.saveCoalesce) {
        folder = base.appendingPathComponent(StorageKeys.historyFolder)
        self.calendar = calendar
        self.delay = delay
    }

    package func append(_ event: HistoryEvent) {
        queue.async { [self] in
            let month = monthName(event.date)
            var events = cache[month] ?? readMonth(month)
            events.append(event)
            cache[month] = events
            dirty.insert(month)
            currentMonth = month
            scheduleWrite()
        }
    }

    package func events(from start: Date, to end: Date) -> [HistoryEvent] {
        queue.sync {
            months(from: start, to: end)
                .flatMap { cache[$0] ?? readMonth($0) }
                .filter { $0.date >= start && $0.date < end }
                .sorted { $0.date < $1.date }
        }
    }

    @discardableResult
    package func flush() -> Bool {
        queue.sync { writeDirty() }
    }

    private func scheduleWrite() {
        guard !isScheduled else { return }
        isScheduled = true
        queue.asyncAfter(deadline: .now() + delay) { [self] in writeDirty() }
    }

    @discardableResult
    private func writeDirty() -> Bool {
        isScheduled = false
        for month in dirty where !blocked.contains(month) && JSONFiles.write(cache[month] ?? [], to: url(month)) {
            dirty.remove(month)
        }
        cache = cache.filter { $0.key == currentMonth || dirty.contains($0.key) }
        return dirty.isEmpty
    }

    private func readMonth(_ month: String) -> [HistoryEvent] {
        guard !blocked.contains(month) else { return [] }
        switch JSONFiles.load([HistoryEvent].self, from: url(month)) {
        case .missing: return []
        case let .value(events): return events
        case .unreadable:
            blocked.insert(month)
            return []
        }
    }

    private func url(_ month: String) -> URL {
        folder.appendingPathComponent(month + ".json")
    }

    private func monthName(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", c.year ?? 0, c.month ?? 0)
    }

    private func months(from start: Date, to end: Date) -> [String] {
        guard start < end, var month = calendar.dateInterval(of: .month, for: start)?.start else { return [] }
        var names: [String] = []
        while month < end {
            names.append(monthName(month))
            guard let next = calendar.date(byAdding: .month, value: 1, to: month) else { break }
            month = next
        }
        return names
    }
}
