import Foundation

package struct WaterRules: HabitRules {
    package let id = HabitID.water
    private let prefs: Prefs
    private let clock: DayClock

    package init(prefs: Prefs, calendar: Calendar = .current) {
        self.prefs = prefs
        clock = DayClock(calendar: calendar)
    }

    package var dailyGoal: Double { prefs.water.dailyGoalGlasses }

    private var days: HabitDays { prefs.days(id) }

    package func nextDue(now: Date, lastDone: Date?, doneToday _: Double, skipToday _: Bool) -> Date {
        days.moveOffDay(dueByHours(now: now, lastDone: lastDone), calendar: clock.calendar, at: start)
    }

    package func isActiveTime(_ date: Date) -> Bool {
        let m = clock.minutesOfDay(date)
        return days.isOn(date, calendar: clock.calendar) && m >= prefs.water.startMinutes && m < prefs.water.endMinutes
    }

    package func nextActiveStart(after date: Date) -> Date {
        days.nextStart(after: date, calendar: clock.calendar, at: start)
    }

    package func nextSlot(after _: Date) -> Date? { nil }

    package func total(on day: Date, data: Persisted) -> Double {
        Stats(calendar: clock.calendar).total(id, on: day, in: data.events)
    }

    private func dueByHours(now: Date, lastDone: Date?) -> Date {
        let candidate = (lastDone ?? now).addingTimeInterval(TimeInterval(prefs.water.intervalMinutes) * Timing.minute)
        let m = clock.minutesOfDay(candidate)
        if m < prefs.water.startMinutes { return start(candidate) }
        if m >= prefs.water.endMinutes { return start(dayAfter(candidate)) }
        return candidate
    }

    private func start(_ day: Date) -> Date {
        clock.at(prefs.water.startMinutes, on: day)
    }

    private func dayAfter(_ date: Date) -> Date {
        clock.calendar.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(Timing.day)
    }
}
