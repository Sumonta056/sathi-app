import Foundation

package struct MeditationRules: HabitRules {
    package let id = HabitID.meditation
    private let prefs: Prefs
    private let clock: DayClock

    package init(prefs: Prefs, calendar: Calendar = .current) {
        self.prefs = prefs
        clock = DayClock(calendar: calendar)
    }

    private var med: MeditationPrefs { prefs.meditation }

    private var days: HabitDays { prefs.days(id) }

    package var dailyGoal: Double { Double(med.dailyGoalMinutes) }

    package func nextDue(now: Date, lastDone: Date?, doneToday: Double, skipToday: Bool) -> Date {
        if skipToday || (dailyGoal > 0 && doneToday >= dailyGoal) {
            return days.firstReminder(onOrAfter: dayAfter(now), calendar: clock.calendar, at: start)
        }
        return days.moveOffDay(dueByHours(now: now, lastDone: lastDone), calendar: clock.calendar, at: start)
    }

    package func isActiveTime(_ date: Date) -> Bool {
        let m = clock.minutesOfDay(date)
        return days.isOn(date, calendar: clock.calendar) && m >= med.startMinutes && m < med.endMinutes
    }

    package func nextActiveStart(after date: Date) -> Date {
        days.nextStart(after: date, calendar: clock.calendar, at: start)
    }

    package func nextSlot(after _: Date) -> Date? { nil }

    package func total(on day: Date, data: Persisted) -> Double {
        Stats(calendar: clock.calendar).total(id, on: day, in: data.events)
    }

    private func dueByHours(now: Date, lastDone: Date?) -> Date {
        let candidate = (lastDone ?? now).addingTimeInterval(TimeInterval(med.intervalMinutes) * Timing.minute)
        let m = clock.minutesOfDay(candidate)
        if m < med.startMinutes { return start(candidate) }
        if m >= med.endMinutes { return start(dayAfter(candidate)) }
        return candidate
    }

    private func start(_ day: Date) -> Date {
        clock.at(med.startMinutes, on: day)
    }

    private func dayAfter(_ date: Date) -> Date {
        clock.calendar.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(Timing.day)
    }
}
