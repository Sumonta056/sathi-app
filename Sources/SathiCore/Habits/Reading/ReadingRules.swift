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

    package func nextDue(now: Date, lastDone _: Date?, doneToday: Double, skipToday: Bool) -> Date {
        let today = clock.calendar.startOfDay(for: now)
        let start = skipToday || doneToday >= dailyGoal ? day(after: today, by: 1) : today
        return firstSlot(from: start) { _ in true }
    }

    package func isActiveTime(_: Date) -> Bool { true }

    package func nextActiveStart(after date: Date) -> Date { date }

    package func nextSlot(after date: Date) -> Date? {
        firstSlot(from: clock.calendar.startOfDay(for: date)) { $0 > date }
    }

    package func total(on day: Date, data: Persisted) -> Double {
        Stats(calendar: clock.calendar).total(id, on: day, in: data.events)
    }

    private func firstSlot(from start: Date, where accept: (Date) -> Bool) -> Date {
        for step in 0 ... Limits.daysPerWeek {
            let d = day(after: start, by: step)
            let slot = clock.at(prefs.reading.timeMinutes, on: d)
            if isSelected(d), accept(slot) { return slot }
        }
        return clock.at(prefs.reading.timeMinutes, on: day(after: start, by: Limits.daysPerWeek))
    }

    private func isSelected(_ date: Date) -> Bool {
        let days = prefs.reading.weekdays
        guard !days.isEmpty, let w = Weekday(rawValue: clock.calendar.component(.weekday, from: date)) else { return true }
        return days.contains(w)
    }

    private func day(after date: Date, by count: Int) -> Date {
        clock.calendar.date(byAdding: .day, value: count, to: date) ?? date.addingTimeInterval(Double(count) * Timing.day)
    }
}
