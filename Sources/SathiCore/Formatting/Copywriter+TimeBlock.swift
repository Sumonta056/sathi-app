import Foundation

extension Copywriter {
    package static let blockDefaultTitle = "Work"
    package static let blockTooShort = "Too short, not saved."

    package static func blockMinutes(_ minutes: Int) -> String {
        let h = minutes / Limits.minutesPerHour
        let m = minutes % Limits.minutesPerHour
        if h == 0 { return "\(m)m" }
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    package static func blockSavedPrevious(minutes: Int, title: String, calendar: String) -> String {
        "Saved \(minutes) min on \(title) to \(calendar)."
    }

    package static func blockCalendarGone(_ name: String) -> String {
        "Your calendar “\(name)” is gone"
    }

    package static func blockSaveFailed(_ name: String) -> String {
        "Sathi could not save to “\(name)”"
    }

    package static func blockStillOn(_ title: String) -> String {
        "Still on \(title)?"
    }
}
