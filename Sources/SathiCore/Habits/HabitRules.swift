import Foundation

package protocol HabitRules: Sendable {
    var id: HabitID { get }
    var dailyGoal: Double { get }
    func nextDue(now: Date, lastDone: Date?, doneToday: Double, skipToday: Bool) -> Date
    func isActiveTime(_ date: Date) -> Bool
    func nextActiveStart(after date: Date) -> Date
    func nextSlot(after date: Date) -> Date?
    func total(on day: Date, data: Persisted) -> Double
}

extension HabitID {
    package func rules(_ prefs: Prefs, calendar: Calendar = .current) -> any HabitRules {
        switch self {
        case .water: return WaterRules(prefs: prefs, calendar: calendar)
        case .reading: return ReadingRules(prefs: prefs, calendar: calendar)
        case .meditation: return MeditationRules(prefs: prefs, calendar: calendar)
        }
    }
}
