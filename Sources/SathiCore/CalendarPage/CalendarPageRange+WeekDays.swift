import Foundation

extension CalendarPageRange {
    var isCustomWeek: Bool {
        kind == .week && weekDays != Limits.calendarDefaultWeekDays
    }

    static func centered(on pageDay: DayKey, count: Int, calendar cal: Calendar) -> CalendarPageRange {
        span(from: pageDay, offset: -(count / 2), count: count, calendar: cal)
    }

    func moved(by step: Int) -> CalendarPageRange {
        let first = days.first ?? DayKey(interval.start, calendar: calendar)
        return Self.span(from: first, offset: step * weekDays, count: weekDays, calendar: calendar)
    }

    private static func span(from day: DayKey, offset: Int, count: Int, calendar cal: Calendar) -> CalendarPageRange {
        let start = day.start(in: cal)
        let days = (0 ..< count).map { index in
            DayKey(cal.date(byAdding: .day, value: offset + index, to: start) ?? start, calendar: cal)
        }
        return build(kind: .week, days: days, fallback: day, calendar: cal, weekDays: count)
    }
}
