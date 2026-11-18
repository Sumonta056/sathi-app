import Foundation

package struct CalendarPageRange: Equatable, Sendable {
    package let kind: ReportRange
    package let days: [DayKey]
    package let interval: DateInterval
    package let weekDays: Int
    let calendar: Calendar

    package static func == (lhs: CalendarPageRange, rhs: CalendarPageRange) -> Bool {
        lhs.kind == rhs.kind && lhs.days == rhs.days && lhs.interval == rhs.interval
            && (lhs.kind != .week || lhs.weekDays == rhs.weekDays)
            && lhs.calendar.firstWeekday == rhs.calendar.firstWeekday
            && lhs.calendar.timeZone == rhs.calendar.timeZone
    }

    package static func containing(
        _ date: Date, kind: ReportRange, calendar: Calendar, weekDays: Int = Limits.calendarDefaultWeekDays
    ) -> CalendarPageRange {
        let cal = pageCalendar(calendar)
        let pageDay = CalendarPageDay.key(holding: date, calendar: cal)
        return make(day: pageDay, kind: kind, calendar: cal, weekDays: weekDays)
    }

    package static func containing(
        day pageDay: DayKey, kind: ReportRange, calendar: Calendar, weekDays: Int = Limits.calendarDefaultWeekDays
    ) -> CalendarPageRange {
        make(day: pageDay, kind: kind, calendar: pageCalendar(calendar), weekDays: weekDays)
    }

    private static func pageCalendar(_ calendar: Calendar) -> Calendar {
        var cal = Calendar.gregorian(in: calendar.timeZone)
        cal.firstWeekday = Limits.calendarPageFirstWeekday
        return cal
    }

    private static func make(day pageDay: DayKey, kind: ReportRange, calendar cal: Calendar, weekDays: Int) -> CalendarPageRange {
        let count = Limits.calendarWeekDays.contains(weekDays) ? weekDays : Limits.calendarDefaultWeekDays
        if kind == .week, count != Limits.calendarDefaultWeekDays {
            return centered(on: pageDay, count: count, calendar: cal)
        }
        let stats = StatsRange.containing(pageDay.start(in: cal), kind: kind, calendar: cal)
        let days = stats.days.map { DayKey($0.start, calendar: cal) }
        return build(kind: kind, days: days, fallback: pageDay, calendar: cal, weekDays: count)
    }

    static func build(
        kind: ReportRange, days: [DayKey], fallback: DayKey, calendar cal: Calendar, weekDays: Int
    ) -> CalendarPageRange {
        let first = days.first ?? fallback
        let last = days.last ?? fallback
        let interval = DateInterval(
            start: CalendarPageDay.interval(of: first, calendar: cal).start,
            end: CalendarPageDay.interval(of: last, calendar: cal).end
        )
        return CalendarPageRange(kind: kind, days: days, interval: interval, weekDays: weekDays, calendar: cal)
    }

    package var previous: CalendarPageRange { shifted(by: -1) }

    package var next: CalendarPageRange { shifted(by: 1) }

    package func changed(to newKind: ReportRange, now: Date) -> CalendarPageRange {
        let anchor = holds(now) ? now : interval.start
        return .containing(anchor, kind: newKind, calendar: calendar, weekDays: weekDays)
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
        if isCustomWeek { return moved(by: step) }
        let stats = StatsRange.containing(firstStart, kind: kind, calendar: calendar)
        let moved = step < 0 ? stats.previous : stats.next
        let day = DayKey(moved.interval.start, calendar: calendar)
        return .make(day: day, kind: kind, calendar: calendar, weekDays: weekDays)
    }

    private var firstStart: Date {
        days.first?.start(in: calendar) ?? interval.start
    }
}
