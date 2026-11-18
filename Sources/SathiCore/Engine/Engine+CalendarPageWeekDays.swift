import Foundation

extension Engine {
    package func setCalendarWeekDays(_ n: Int) {
        guard Limits.calendarWeekDays.contains(n) else { return }
        data.prefs.calendarPage.weekDays = n
    }

    package func calendarPageToday(_ kind: ReportRange) -> CalendarPageRange {
        .containing(clock.now, kind: kind, calendar: calendar, weekDays: data.prefs.calendarPage.weekDays)
    }
}
