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

    package var dailyGoal: Double { Double(gym.dailyGoalMinutes) }

    package func nextDue(now: Date, lastDone: Date?, doneToday: Double, skipToday: Bool) -> Date {
        guard gym.startMinutes < gym.endMinutes else { return .distantFuture }
        let left = sessionsLeft(doneToday)
        let start = clock.at(gym.startMinutes, on: now)
        let end = end(of: now)
        let tomorrow = firstReminder(onOrAfter: day(after: now, by: 1))
        guard !skipToday, left > 0, days.isOn(now, calendar: clock.calendar), now < end else { return tomorrow }
        guard let d = lastDone, d >= start, d < end else {
            return start.addingTimeInterval(end.timeIntervalSince(start) / Double(2 * left))
        }
        let gap = max(end.timeIntervalSince(d) / (Double(left) + Self.halfSession), session)
        let due = d.addingTimeInterval(gap)
        return due < end ? due : tomorrow
    }

    private static let halfSession = 0.5

    private var session: TimeInterval { TimeInterval(gym.sessionMinutes) * Timing.minute }

    private func sessionsLeft(_ done: Double) -> Int {
        let rest = dailyGoal - done
        return rest > 0 ? Int((rest / Double(gym.sessionMinutes)).rounded(.up)) : 0
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
        days.firstReminder(onOrAfter: date, calendar: clock.calendar, at: firstOf)
    }

    private func firstOf(_ date: Date) -> Date {
        let start = clock.at(gym.startMinutes, on: date)
        let span = end(of: date).timeIntervalSince(start)
        return start.addingTimeInterval(span / Double(2 * gym.sessionsPerDay))
    }

    private func end(of date: Date) -> Date {
        clock.at(gym.endMinutes, on: date)
    }

    private func day(after date: Date, by count: Int) -> Date {
        clock.calendar.date(byAdding: .day, value: count, to: date) ?? date.addingTimeInterval(Double(count) * Timing.day)
    }
}
