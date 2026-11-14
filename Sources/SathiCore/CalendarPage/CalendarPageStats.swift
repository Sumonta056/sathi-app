import Foundation

package struct CalendarCategoryTime: Equatable, Sendable {
    package var name: String?
    package var seconds: TimeInterval

    package init(name: String?, seconds: TimeInterval) {
        self.name = name
        self.seconds = seconds
    }
}

package struct CalendarPageStats: Equatable, Sendable {
    package var tracked: TimeInterval
    package var planned: TimeInterval
    package var byCategory: [CalendarCategoryTime]
    package var away: TimeInterval

    package init(tracked: TimeInterval = 0, planned: TimeInterval = 0, byCategory: [CalendarCategoryTime] = [], away: TimeInterval = 0) {
        self.tracked = tracked
        self.planned = planned
        self.byCategory = byCategory
        self.away = away
    }

    package static func make(events: [CalendarEventInfo], activities: [Activity], interval: DateInterval) -> CalendarPageStats {
        let tracking = activities.filter { $0.kind != .away }
        var byName: [String?: TimeInterval] = [:]
        for row in tracking {
            byName[row.category, default: 0] += clipped(row.start, row.end, to: interval)
        }
        let categories = byName.filter { $0.value > 0 }
            .map { CalendarCategoryTime(name: $0.key, seconds: $0.value) }
            .sorted { $0.seconds != $1.seconds ? $0.seconds > $1.seconds : ($0.name ?? "") < ($1.name ?? "") }
        return CalendarPageStats(
            tracked: categories.reduce(0) { $0 + $1.seconds },
            planned: planned(events, in: interval),
            byCategory: categories,
            away: activities.filter { $0.kind == .away }.reduce(0) { $0 + clipped($1.start, $1.end, to: interval) }
        )
    }

    package static func tracked(_ activities: [Activity], in interval: DateInterval) -> TimeInterval {
        activities.filter { $0.kind != .away }.reduce(0) { $0 + clipped($1.start, $1.end, to: interval) }
    }

    private static func planned(_ events: [CalendarEventInfo], in interval: DateInterval) -> TimeInterval {
        let spans = events.filter { !$0.isAllDay && !$0.declined }
            .map { (max($0.start, interval.start), min($0.end, interval.end)) }
            .filter { $0.0 < $0.1 }
            .sorted { $0.0 < $1.0 }
        var total: TimeInterval = 0
        var open: (Date, Date)?
        for span in spans {
            if let o = open, span.0 <= o.1 {
                open = (o.0, max(o.1, span.1))
            } else {
                if let o = open { total += o.1.timeIntervalSince(o.0) }
                open = span
            }
        }
        if let o = open { total += o.1.timeIntervalSince(o.0) }
        return total
    }

    private static func clipped(_ start: Date, _ end: Date, to interval: DateInterval) -> TimeInterval {
        max(0, min(end, interval.end).timeIntervalSince(max(start, interval.start)))
    }
}
