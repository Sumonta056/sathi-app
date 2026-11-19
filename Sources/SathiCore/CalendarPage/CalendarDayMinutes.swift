import Foundation

struct CalendarDayMinutes {
    let interval: DateInterval
    private let calendar: Calendar

    init(day: DayKey, calendar: Calendar) {
        interval = CalendarPageDay.interval(of: day, calendar: calendar)
        self.calendar = Calendar.gregorian(in: calendar.timeZone)
    }

    func minute(_ date: Date) -> Int {
        if date <= interval.start { return 0 }
        if date >= interval.end { return Limits.minutesPerDay }
        let c = calendar.dateComponents([.hour, .minute], from: date)
        let hour = c.hour ?? 0
        let wall = (hour - Limits.calendarPageDayStartHour) * Limits.minutesPerHour + (c.minute ?? 0)
        let m = hour < Limits.calendarPageDayStartHour ? wall + Limits.minutesPerDay : wall
        return min(max(m, 0), Limits.minutesPerDay)
    }

    func minutes(_ span: DateInterval) -> Range<Int> {
        let from = minute(span.start)
        return from ..< max(from, minute(span.end))
    }
}
