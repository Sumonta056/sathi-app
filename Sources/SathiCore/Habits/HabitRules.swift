import Foundation

package protocol HabitRules: Sendable {
    var id: HabitID { get }
    var dailyGoal: Double { get }
    func scheduledDue(now: Date, lastDone: Date?, doneToday: Double) -> Date
    func firstDue(onDayAfter date: Date) -> Date
    func isActiveTime(_ date: Date) -> Bool
    func nextActiveStart(after date: Date) -> Date
    func nextSlot(after date: Date) -> Date?
    func total(on day: Date, data: Persisted) -> Double
}

extension HabitRules {
    package func isGoalMet(_ doneToday: Double) -> Bool {
        dailyGoal > 0 && doneToday >= dailyGoal
    }

    package func nextDue(now: Date, lastDone: Date?, doneToday: Double, skipToday: Bool) -> Date {
        if skipToday || isGoalMet(doneToday) { return firstDue(onDayAfter: now) }
        return scheduledDue(now: now, lastDone: lastDone, doneToday: doneToday)
    }
}

extension HabitID {
    package func rules(_ prefs: Prefs, calendar: Calendar = .current) -> any HabitRules {
        switch self {
        case .water: return WaterRules(prefs: prefs, calendar: calendar)
        case .reading: return ReadingRules(prefs: prefs, calendar: calendar)
        case .meditation: return MeditationRules(prefs: prefs, calendar: calendar)
        case .gym: return GymRules(prefs: prefs, calendar: calendar)
        }
    }
}
