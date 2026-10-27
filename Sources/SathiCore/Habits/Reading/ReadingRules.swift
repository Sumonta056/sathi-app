import Foundation

package struct ReadingRules: HabitRules {
    package let id = HabitID.reading
    private let prefs: Prefs
    private let clock: DayClock

    package init(prefs: Prefs, calendar: Calendar = .current) {
        self.prefs = prefs
        clock = DayClock(calendar: calendar)
    }

    package var dailyGoal: Double { Double(prefs.reading.sessionMinutes) }

    private var days: HabitDays { prefs.days(id) }

    package func nextDue(now: Date, lastDone _: Date?, doneToday: Double, skipToday: Bool) -> Date {
        let today = clock.calendar.startOfDay(for: now)
        let start = skipToday || doneToday >= dailyGoal ? dayAfter(today) : today
        return days.firstReminder(onOrAfter: start, calendar: clock.calendar, at: slot)
    }

    package func isActiveTime(_ date: Date) -> Bool {
        days.isOn(date, calendar: clock.calendar)
    }

    package func nextActiveStart(after date: Date) -> Date {
        days.isOn(date, calendar: clock.calendar) ? date : days.nextStart(after: date, calendar: clock.calendar, at: slot)
    }

    package func nextSlot(after date: Date) -> Date? {
        let first = days.firstReminder(onOrAfter: date, calendar: clock.calendar, at: slot)
        if first > date { return first }
        return days.firstReminder(onOrAfter: dayAfter(first), calendar: clock.calendar, at: slot)
    }

    package func total(on day: Date, data: Persisted) -> Double {
        Stats(calendar: clock.calendar).total(id, on: day, in: data.events)
    }

    private func slot(_ day: Date) -> Date {
        clock.at(prefs.reading.timeMinutes, on: day)
    }

    private func dayAfter(_ date: Date) -> Date {
        clock.calendar.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(Timing.day)
    }
}
