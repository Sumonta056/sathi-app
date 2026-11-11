import Foundation

package struct StatsRange: Equatable, Sendable {
    package let kind: ReportRange
    package let interval: DateInterval
    private let calendar: Calendar

    package static func == (lhs: StatsRange, rhs: StatsRange) -> Bool {
        lhs.kind == rhs.kind && lhs.interval == rhs.interval
    }

    package static func containing(_ date: Date, kind: ReportRange, calendar: Calendar) -> StatsRange {
        var cal = Calendar.gregorian(in: calendar.timeZone)
        cal.firstWeekday = calendar.firstWeekday
        let today = cal.startOfDay(for: date)
        let start: Date
        let end: Date
        switch kind {
        case .day:
            start = today
            end = cal.nextDay(after: today)
        case .week:
            let weekday = cal.component(.weekday, from: today)
            let offset = (weekday - cal.firstWeekday + Limits.daysPerWeek) % Limits.daysPerWeek
            start = cal.stepDays(-offset, from: today)
            end = cal.stepDays(Limits.daysPerWeek, from: start)
        case .month:
            let month = cal.dateInterval(of: .month, for: today)
            start = month?.start ?? today
            end = month?.end ?? cal.nextDay(after: today)
        }
        return StatsRange(kind: kind, interval: DateInterval(start: start, end: end), calendar: cal)
    }

    package var previous: StatsRange {
        .containing(interval.start.addingTimeInterval(-Timing.second), kind: kind, calendar: calendar)
    }

    package var next: StatsRange {
        .containing(interval.end, kind: kind, calendar: calendar)
    }

    package func holds(_ date: Date) -> Bool {
        interval.start <= date && date < interval.end
    }

    package var days: [DateInterval] {
        var result: [DateInterval] = []
        var day = interval.start
        while day < interval.end {
            let end = calendar.nextDay(after: day)
            result.append(DateInterval(start: day, end: end))
            day = end
        }
        return result
    }

    package func canGoForward(now: Date) -> Bool {
        !holds(now)
    }

    package func changed(to newKind: ReportRange, now: Date) -> StatsRange {
        .containing(holds(now) ? now : interval.start, kind: newKind, calendar: calendar)
    }
}
