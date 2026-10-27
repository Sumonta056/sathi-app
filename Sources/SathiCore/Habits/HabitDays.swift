import Foundation

package struct HabitDays: Equatable, Sendable {
    package var weekdays: Set<Weekday>
    package var daysOff: Set<DayKey>

    package init(weekdays: Set<Weekday>, daysOff: Set<DayKey>) {
        self.weekdays = weekdays
        self.daysOff = daysOff
    }

    package func isOn(_ date: Date, calendar: Calendar) -> Bool {
        let g = Calendar.gregorian(in: calendar.timeZone)
        let on = weekdays.isEmpty ? Set(Weekday.allCases) : weekdays
        guard let w = Weekday(rawValue: g.component(.weekday, from: date)), on.contains(w) else { return false }
        return !daysOff.contains(DayKey(date, calendar: g))
    }

    package func nextOnDay(onOrAfter date: Date, calendar: Calendar) -> Date? {
        let g = Calendar.gregorian(in: calendar.timeZone)
        var day = g.startOfDay(for: date)
        for _ in 0 ... Limits.daysPerWeek * 2 {
            if isOn(day, calendar: g) { return day }
            day = g.nextDay(after: day)
        }
        return nil
    }

    package func upcoming(from now: Date, calendar: Calendar) -> [DayKey] {
        let today = DayKey(now, calendar: calendar)
        return daysOff.filter { $0 >= today }.sorted()
    }
}
