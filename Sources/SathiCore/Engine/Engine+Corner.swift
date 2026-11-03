import Foundation

extension Engine {
    package func usesCorner(_ id: HabitID) -> Bool {
        switch id {
        case .water: return false
        case .reading: return data.prefs.reading.reminderStyle == .corner
        case .meditation: return false
        case .gym: return true
        }
    }

    package func showsClose(_ id: HabitID, level: Level) -> Bool {
        data.prefs.showsCloseButton(id) && level == .nudge && canSnooze(id)
    }

    package var snoozeShortLabel: String { "In \(data.prefs.general.snoozeMinutes) min" }

    package func comesBackText(_ id: HabitID, until: Date) -> String {
        Copywriter.comesBack(id, at: until, calendar: calendar)
    }
}
