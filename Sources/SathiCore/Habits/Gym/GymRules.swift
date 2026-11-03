import Foundation

package struct GymRules: HabitRules {
    package let id = HabitID.gym
    private let prefs: Prefs
    private let clock: DayClock

    package init(prefs: Prefs, calendar: Calendar = .current) {
        self.prefs = prefs
        clock = DayClock(calendar: calendar)
    }

    private var gym: GymPrefs { prefs.gym }

    private var days: HabitDays { prefs.days(id) }

    private var interval: TimeInterval { TimeInterval(gym.intervalMinutes) * Timing.minute }

    package var dailyGoal: Double { Double(Limits.gymDailyGoal) }

    package func nextDue(now: Date, lastDone: Date?, doneToday _: Double, skipToday: Bool) -> Date {
        if skipToday { return firstReminder(onOrAfter: day(after: now, by: 1)) }
        let cal = clock.calendar
        let fresh = lastDone.flatMap { cal.startOfDay(for: $0) < cal.startOfDay(for: now) ? nil : $0 }
        let candidate = (fresh ?? now).addingTimeInterval(interval)
        let due = max(candidate, firstOf(candidate))
        if days.isOn(candidate, calendar: cal), due < end(of: candidate) { return due }
        return firstReminder(onOrAfter: day(after: candidate, by: 1))
    }

    package func isActiveTime(_ date: Date) -> Bool {
        let m = clock.minutesOfDay(date)
        return days.isOn(date, calendar: clock.calendar) && m >= gym.startMinutes && m < gym.endMinutes
    }

    package func nextActiveStart(after date: Date) -> Date {
        days.nextStart(after: date, calendar: clock.calendar) { clock.at(gym.startMinutes, on: $0) }
    }

    package func nextSlot(after _: Date) -> Date? { nil }

    package func total(on day: Date, data: Persisted) -> Double {
        Stats(calendar: clock.calendar).total(id, on: day, in: data.events)
    }

    private func firstReminder(onOrAfter date: Date) -> Date {
        days.firstReminder(onOrAfter: date, calendar: clock.calendar) { firstOf($0) < end(of: $0) ? firstOf($0) : .distantFuture }
    }

    private func firstOf(_ date: Date) -> Date {
        clock.at(gym.startMinutes, on: date).addingTimeInterval(interval)
    }

    private func end(of date: Date) -> Date {
        clock.at(gym.endMinutes, on: date)
    }

    private func day(after date: Date, by count: Int) -> Date {
        clock.calendar.date(byAdding: .day, value: count, to: date) ?? date.addingTimeInterval(Double(count) * Timing.day)
    }
}
