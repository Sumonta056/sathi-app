import Foundation

package enum Strictness: String, Codable, CaseIterable, Identifiable, Sendable {
    case friendly, persistent, strict

    package var id: String { rawValue }

    package var title: String {
        switch self {
        case .friendly: return "Gentle"
        case .persistent: return "Nudgy"
        case .strict: return "Strict"
        }
    }

    package var detail: String {
        switch self {
        case .friendly: return "A reminder each time. It never stays on top."
        case .persistent: return "Stays on top, wiggles, and has no close button after a snooze."
        case .strict: return "Locks the screen after two snoozes."
        }
    }

    package var level: Int {
        switch self {
        case .friendly: return 1
        case .persistent: return 2
        case .strict: return 3
        }
    }
}
