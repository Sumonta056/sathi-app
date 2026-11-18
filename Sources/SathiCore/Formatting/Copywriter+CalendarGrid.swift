import Foundation

extension Copywriter {
    package static let calendarAllDay = "All day"
    package static let calendarMidday = "Midday"

    package static func calendarHourLabel(hour: Int) -> String {
        let half = Limits.calendarGridHours / 2
        if hour == half { return calendarMidday }
        let shown = hour % half == 0 ? half : hour % half
        return "\(shown) " + (hour < half ? "AM" : "PM")
    }

    package static func calendarCopies(_ count: Int) -> String {
        "×\(count)"
    }

    package static func calendarCopiesSpoken(_ count: Int) -> String {
        "in \(count) calendars"
    }

    package static func calendarMore(_ count: Int) -> String {
        "+\(count) more"
    }

    package static func calendarWeekday(_ day: DayKey, calendar: Calendar) -> String {
        let g = Calendar.gregorian(in: calendar.timeZone)
        let index = g.component(.weekday, from: day.start(in: g)) - 1
        return calendarWeekdayNames[index]
    }

    package static func calendarBlockSpoken(_ title: String, _ start: Date, _ end: Date, calendar: Calendar) -> String {
        title + ", " + trackerClock(start, calendar: calendar) + " to " + trackerClock(end, calendar: calendar)
    }

    private static let calendarWeekdayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    package static func calendarDayNumber(_ day: DayKey, calendar: Calendar) -> String {
        let g = Calendar.gregorian(in: calendar.timeZone)
        return String(g.component(.day, from: day.start(in: g)))
    }
}
