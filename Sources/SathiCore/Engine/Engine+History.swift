import Foundation

extension Engine {
    nonisolated static func windowStart(now: Date, calendar: Calendar) -> Date {
        let month = calendar.dateInterval(of: .month, for: now)?.start ?? now
        return calendar.date(byAdding: .month, value: -(Limits.monthsInMemory - 1), to: month) ?? month
    }

    func record(_ event: HistoryEvent) {
        let start = Self.windowStart(now: clock.now, calendar: calendar)
        var events = data.events
        events.append(event)
        events.removeAll { $0.date < start }
        data.events = events
        history.append(event)
    }
}
