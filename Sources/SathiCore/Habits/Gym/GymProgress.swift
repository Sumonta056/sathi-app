import Foundation

package struct GymProgress: Equatable, Sendable {
    package let sessions: Int
    package let filled: Int
    package let doneMinutes: Int
    package let goalMinutes: Int

    package init(prefs: GymPrefs, doneMinutes: Double) {
        sessions = prefs.sessionsPerDay
        goalMinutes = prefs.dailyGoalMinutes
        self.doneMinutes = min(Int(doneMinutes), goalMinutes)
        filled = min(sessions, Int(doneMinutes) / prefs.sessionMinutes)
    }

    package var current: Int { min(filled + 1, sessions) }
}
