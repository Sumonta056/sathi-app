import Foundation

extension Copywriter {
    package static let calendarActualLabel = "ACTUAL"
    package static let calendarPlanLabel = "PLAN"
    package static let calendarFoldNote = "away or nothing on every shown day"

    private static let calendarMonthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    package static func calendarWeekDayHeader(_ day: DayKey, calendar: Calendar) -> String {
        calendarWeekday(day, calendar: calendar) + " " + calendarDayNumber(day, calendar: calendar) + " "
            + calendarMonthShort(day, calendar: calendar)
    }

    package static func calendarMonthShort(_ day: DayKey, calendar: Calendar) -> String {
        let g = Calendar.gregorian(in: calendar.timeZone)
        return calendarMonthNames[g.component(.month, from: day.start(in: g)) - 1]
    }

    package static func calendarWeekDaysOption(_ n: Int) -> String {
        "\(n) days"
    }

    package static func calendarStartClock(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return clock(hour: parts.hour ?? 0, minute: parts.minute ?? 0).time
    }

    package static func calendarFoldText(fromMinute from: Int, toMinute to: Int) -> String {
        let start = pageClock(from)
        let end = pageClock(to)
        let head = start.half == end.half ? start.time : start.time + " " + start.half
        return head + " – " + end.time + " " + end.half + " · " + calendarFoldNote
    }

    private static func pageClock(_ minute: Int) -> (time: String, half: String) {
        let wall = Limits.calendarPageDayStartHour * Limits.minutesPerHour + minute
        let hour = (wall / Limits.minutesPerHour) % Limits.hoursPerDay
        return clock(hour: hour, minute: wall % Limits.minutesPerHour)
    }

    private static func clock(hour: Int, minute: Int) -> (time: String, half: String) {
        let half = Limits.hoursPerDay / 2
        let shown = hour % half == 0 ? half : hour % half
        return (String(format: "%d:%02d", shown, minute), hour < half ? "AM" : "PM")
    }
}
