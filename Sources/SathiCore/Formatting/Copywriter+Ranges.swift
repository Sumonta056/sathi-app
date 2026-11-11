import Foundation

extension Copywriter {
    package static func rangeSegment(_ kind: ReportRange) -> String {
        switch kind {
        case .day: "Day"
        case .week: "Week"
        case .month: "Month"
        }
    }

    package static func rangeTitle(_ range: StatsRange, now: Date, calendar: Calendar) -> String {
        let zone = calendar.timeZone
        let start = range.interval.start
        switch range.kind {
        case .day:
            let today = calendar.startOfDay(for: now)
            let date = rangeDate(start, "d MMM", zone)
            if start == today { return "Today, " + date }
            if start == calendar.date(byAdding: .day, value: -1, to: today) { return "Yesterday, " + date }
            return rangeDate(start, "EEE", zone) + ", " + date
        case .week:
            let last = calendar.date(byAdding: .day, value: -1, to: range.interval.end) ?? range.interval.end
            let sameMonth = calendar.component(.month, from: start) == calendar.component(.month, from: last)
            let first = sameMonth ? rangeDate(start, "d", zone) : rangeDate(start, "d MMM", zone)
            return first + " – " + rangeDate(last, "d MMM", zone)
        case .month:
            return rangeDate(start, "MMMM yyyy", zone)
        }
    }

    package static func rangeChange(_ change: RangeChange, kind: ReportRange, format: (Double) -> String) -> String {
        let label = rangeBefore(kind)
        switch change {
        case let .up(amount): return "+" + format(amount) + " vs " + label
        case let .down(amount): return "\u{2212}" + format(amount) + " vs " + label
        case .same: return "same as " + label
        case .none: return ""
        }
    }

    private static func rangeBefore(_ kind: ReportRange) -> String {
        switch kind {
        case .day: "yesterday"
        case .week: "last week"
        case .month: "last month"
        }
    }

    private static func rangeDate(_ date: Date, _ pattern: String, _ zone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = zone
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }
}
