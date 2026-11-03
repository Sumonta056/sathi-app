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
        for _ in 0 ... Limits.daysOffMaxAhead + Limits.daysPerWeek {
            if isOn(day, calendar: g) { return day }
            day = g.nextDay(after: day)
        }
        return nil
    }

    func firstReminder(onOrAfter date: Date, calendar: Calendar, at first: (Date) -> Date) -> Date {
        nextOnDay(onOrAfter: date, calendar: calendar).map(first) ?? .distantFuture
    }

    func moveOffDay(_ due: Date, calendar: Calendar, at first: (Date) -> Date) -> Date {
        guard due != .distantFuture, !isOn(due, calendar: calendar) else { return due }
        let next = Calendar.gregorian(in: calendar.timeZone).nextDay(after: due)
        return firstReminder(onOrAfter: next, calendar: calendar, at: first)
    }

    func nextStart(after date: Date, calendar: Calendar, at first: (Date) -> Date) -> Date {
        let from = first(date) > date ? date : Calendar.gregorian(in: calendar.timeZone).nextDay(after: date)
        return firstReminder(onOrAfter: from, calendar: calendar, at: first)
    }

    package func upcoming(from now: Date, calendar: Calendar) -> [DayKey] {
        let today = DayKey(now, calendar: calendar)
        return daysOff.filter { $0 >= today }.sorted()
    }

    package func addingDayOff(_ date: Date, now: Date, calendar: Calendar) -> HabitDays {
        let g = Calendar.gregorian(in: calendar.timeZone)
        let range = Self.dayOffRange(now: now, calendar: g)
        let key = DayKey(date, calendar: g)
        let today = DayKey(range.lowerBound, calendar: g)
        let isFull = upcoming(from: now, calendar: g).count >= Limits.daysOffMax
        guard key >= today, key <= DayKey(range.upperBound, calendar: g), !daysOff.contains(key), !isFull else { return self }
        var next = self
        next.daysOff.insert(key)
        return next
    }

    package static func dayOffRange(now: Date, calendar: Calendar) -> ClosedRange<Date> {
        let g = Calendar.gregorian(in: calendar.timeZone)
        let today = g.startOfDay(for: now)
        let last = g.stepDays(Limits.daysOffMaxAhead, from: today)
        return today ... g.nextDay(after: last).addingTimeInterval(-Timing.second)
    }
}
