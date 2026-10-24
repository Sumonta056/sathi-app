import Foundation
import SathiCore

enum SessionCopy {
    static func title(_ id: HabitID) -> String {
        switch id {
        case .water: return "WATER"
        case .reading: return "READING · DO NOT DISTURB"
        case .meditation: return "BREATHING"
        }
    }

    static func body(_ id: HabitID) -> String {
        switch id {
        case .water: return ""
        case .reading: return "Boi is reading with you. Water reminders wait until the timer ends."
        case .meditation: return "Shanti is breathing with you. Water reminders wait until the timer ends."
        }
    }

    static func breath(_ id: HabitID, style: BreathingStyle, elapsed: TimeInterval) -> String? {
        switch id {
        case .water, .reading: return nil
        case .meditation: return Copywriter.breathLabel(BreathingPattern.step(style, at: elapsed).phase)
        }
    }
}
