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

    private var interval: TimeInterval { TimeInterval(gym.intervalMinutes) * Timing.minute }

    package var dailyGoal: Double { Double(Limits.gymDailyGoal) }

    package func nextDue(now: Date, lastDone: Date?, doneToday _: Double, skipToday: Bool) -> Date {
        if skipToday { return firstReminder(onOrAfter: day(after: now, by: 1)) }
        let cal = clock.calendar
        let fresh = lastDone.flatMap { cal.startOfDay(for: $0) < cal.startOfDay(for: now) ? nil : $0 }
        let candidate = (fresh ?? now).addingTimeInterval(interval)
        let due = max(candidate, firstOf(candidate))
        if isWorkDay(candidate), due < end(of: candidate) { return due }
        return firstReminder(onOrAfter: day(after: candidate, by: 1))
    }

    package func isActiveTime(_ date: Date) -> Bool {
        let m = clock.minutesOfDay(date)
        return isWorkDay(date) && m >= gym.startMinutes && m < gym.endMinutes
    }

    package func nextActiveStart(after date: Date) -> Date {
        for step in 0 ... Limits.daysPerWeek {
            let start = clock.at(gym.startMinutes, on: day(after: date, by: step))
            if isWorkDay(start), start > date { return start }
        }
        return .distantFuture
    }

    package func nextSlot(after _: Date) -> Date? { nil }

    package func total(on day: Date, data: Persisted) -> Double {
        Stats(calendar: clock.calendar).total(id, on: day, in: data.events)
    }

    private func firstReminder(onOrAfter date: Date) -> Date {
        for step in 0 ... Limits.daysPerWeek {
            let d = day(after: date, by: step)
            if isWorkDay(d), firstOf(d) < end(of: d) { return firstOf(d) }
        }
        return .distantFuture
    }

    private func firstOf(_ date: Date) -> Date {
        clock.at(gym.startMinutes, on: date).addingTimeInterval(interval)
    }

    private func end(of date: Date) -> Date {
        clock.at(gym.endMinutes, on: date)
    }

    private func isWorkDay(_ date: Date) -> Bool {
        let days = gym.weekdays.isEmpty ? Limits.gymWorkDays : gym.weekdays
        guard let w = Weekday(rawValue: clock.calendar.component(.weekday, from: date)) else { return false }
        return days.contains(w)
    }

    private func day(after date: Date, by count: Int) -> Date {
        clock.calendar.date(byAdding: .day, value: count, to: date) ?? date.addingTimeInterval(Double(count) * Timing.day)
    }
}
