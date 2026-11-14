import Foundation

package enum CalendarPageDay {
    package static func interval(of day: DayKey, calendar: Calendar) -> DateInterval {
        let g = Calendar.gregorian(in: calendar.timeZone)
        let midnight = day.start(in: g)
        let start = sixAM(of: midnight, in: g)
        let end = sixAM(of: g.nextDay(after: midnight), in: g)
        return DateInterval(start: start, end: end)
    }

    package static func key(holding date: Date, calendar: Calendar) -> DayKey {
        let g = Calendar.gregorian(in: calendar.timeZone)
        let shifted = g.date(byAdding: .hour, value: -Limits.calendarPageDayStartHour, to: date) ?? date
        let key = DayKey(shifted, calendar: g)
        let start = interval(of: key, calendar: g).start
        if date < start {
            return DayKey(g.previousDay(before: key.start(in: g)), calendar: g)
        }
        if date >= interval(of: key, calendar: g).end {
            return DayKey(g.nextDay(after: key.start(in: g)), calendar: g)
        }
        return key
    }

    package static func hourStarts(of day: DayKey, calendar: Calendar) -> [Date] {
        let g = Calendar.gregorian(in: calendar.timeZone)
        let start = interval(of: day, calendar: g).start
        return (0 ..< Limits.calendarGridHours).compactMap {
            g.date(byAdding: .hour, value: $0, to: start)
        }
    }

    private static func sixAM(of midnight: Date, in calendar: Calendar) -> Date {
        calendar.date(bySettingHour: Limits.calendarPageDayStartHour, minute: 0, second: 0, of: midnight) ?? midnight
    }
}
