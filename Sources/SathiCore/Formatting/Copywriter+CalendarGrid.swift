import Foundation

extension Copywriter {
    package static let calendarAllDay = "All day"
    package static let calendarMidday = "Midday"

    package static func calendarHourLabel(_ date: Date, calendar: Calendar) -> String {
        let hour = Calendar.gregorian(in: calendar.timeZone).component(.hour, from: date)
        let half = Limits.calendarGridHours / 2
        if hour == half { return calendarMidday }
        let shown = hour % half == 0 ? half : hour % half
        return "\(shown) " + (hour < half ? "AM" : "PM")
    }

    package static func calendarMore(_ count: Int) -> String {
        "+\(count) more"
    }

    package static func calendarWeekday(_ day: DayKey, calendar: Calendar) -> String {
        rangeDate(day.start(in: calendar), "EEE", calendar.timeZone)
    }

    package static func calendarDayNumber(_ day: DayKey, calendar: Calendar) -> String {
        let g = Calendar.gregorian(in: calendar.timeZone)
        return String(g.component(.day, from: day.start(in: g)))
    }
}
