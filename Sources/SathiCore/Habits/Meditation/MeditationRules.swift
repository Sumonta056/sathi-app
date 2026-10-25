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

    package var dailyGoal: Double { Double(med.dailyGoalMinutes) }

    package func nextDue(now: Date, lastDone: Date?, doneToday: Double, skipToday: Bool) -> Date {
        if skipToday || (dailyGoal > 0 && doneToday >= dailyGoal) { return clock.at(med.startMinutes, on: dayAfter(now)) }
        let candidate = (lastDone ?? now).addingTimeInterval(TimeInterval(med.intervalMinutes) * Timing.minute)
        let m = clock.minutesOfDay(candidate)
        if m < med.startMinutes { return clock.at(med.startMinutes, on: candidate) }
        if m >= med.endMinutes { return clock.at(med.startMinutes, on: dayAfter(candidate)) }
        return candidate
    }

    package func isActiveTime(_ date: Date) -> Bool {
        let m = clock.minutesOfDay(date)
        return m >= med.startMinutes && m < med.endMinutes
    }

    package func nextActiveStart(after date: Date) -> Date {
        let startToday = clock.at(med.startMinutes, on: date)
        return startToday > date ? startToday : clock.at(med.startMinutes, on: dayAfter(date))
    }

    package func nextSlot(after _: Date) -> Date? { nil }

    private func dayAfter(_ date: Date) -> Date {
        clock.calendar.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(Timing.day)
    }

    package func total(on day: Date, data: Persisted) -> Double {
        Stats(calendar: clock.calendar).total(id, on: day, in: data.events)
    }
}
