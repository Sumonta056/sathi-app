import Foundation

package struct CalendarPageRange: Equatable, Sendable {
    package let kind: ReportRange
    package let days: [DayKey]
    package let interval: DateInterval
    private let calendar: Calendar

    package static func == (lhs: CalendarPageRange, rhs: CalendarPageRange) -> Bool {
        lhs.kind == rhs.kind && lhs.days == rhs.days && lhs.interval == rhs.interval
            && lhs.calendar.firstWeekday == rhs.calendar.firstWeekday
            && lhs.calendar.timeZone == rhs.calendar.timeZone
    }

    package static func containing(_ date: Date, kind: ReportRange, calendar: Calendar) -> CalendarPageRange {
        var cal = Calendar.gregorian(in: calendar.timeZone)
        cal.firstWeekday = Limits.calendarPageFirstWeekday
        let pageDay = CalendarPageDay.key(holding: date, calendar: cal)
        return make(day: pageDay, kind: kind, calendar: cal)
    }

    package static func containing(day pageDay: DayKey, kind: ReportRange, calendar: Calendar) -> CalendarPageRange {
        var cal = Calendar.gregorian(in: calendar.timeZone)
        cal.firstWeekday = Limits.calendarPageFirstWeekday
        return make(day: pageDay, kind: kind, calendar: cal)
    }

    private static func make(day pageDay: DayKey, kind: ReportRange, calendar cal: Calendar) -> CalendarPageRange {
        let stats = StatsRange.containing(pageDay.start(in: cal), kind: kind, calendar: cal)
        let days = stats.days.map { DayKey($0.start, calendar: cal) }
        let first = days.first ?? pageDay
        let last = days.last ?? pageDay
        let interval = DateInterval(
            start: CalendarPageDay.interval(of: first, calendar: cal).start,
            end: CalendarPageDay.interval(of: last, calendar: cal).end
        )
        return CalendarPageRange(kind: kind, days: days, interval: interval, calendar: cal)
    }

    package var previous: CalendarPageRange { shifted(by: -1) }

    package var next: CalendarPageRange { shifted(by: 1) }

    package func changed(to newKind: ReportRange, now: Date) -> CalendarPageRange {
        let anchor = holds(now) ? now : interval.start
        return .containing(anchor, kind: newKind, calendar: calendar)
    }

    package func holds(_ date: Date) -> Bool {
        interval.start <= date && date < interval.end
    }

    package func inRange(_ day: DayKey) -> Bool {
        days.contains(day)
    }

    package var monthWeeks: [[DayKey]] {
        guard let first = days.first, let last = days.last else { return [] }
        let gridStart = StatsRange.containing(first.start(in: calendar), kind: .week, calendar: calendar)
        let gridEnd = StatsRange.containing(last.start(in: calendar), kind: .week, calendar: calendar)
        var weeks: [[DayKey]] = []
        var week = gridStart
        while true {
            weeks.append(week.days.map { DayKey($0.start, calendar: calendar) })
            if week == gridEnd { break }
            week = week.next
        }
        return weeks
    }

    package func initialScrollRow(now: Date) -> Int {
        guard holds(now) else { return 0 }
        let day = CalendarPageDay.key(holding: now, calendar: calendar)
        let rows = CalendarPageDay.hourStarts(of: day, calendar: calendar)
        return rows.lastIndex { $0 <= now } ?? 0
    }

    private func shifted(by step: Int) -> CalendarPageRange {
        let stats = StatsRange.containing(firstStart, kind: kind, calendar: calendar)
        let moved = step < 0 ? stats.previous : stats.next
        return .make(day: DayKey(moved.interval.start, calendar: calendar), kind: kind, calendar: calendar)
    }

    private var firstStart: Date {
        days.first?.start(in: calendar) ?? interval.start
    }
}
