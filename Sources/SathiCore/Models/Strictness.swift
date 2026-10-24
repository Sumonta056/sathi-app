import Foundation

package enum Strictness: String, Codable, CaseIterable, Identifiable, Sendable {
    case friendly, persistent, strict

    package var id: String { rawValue }

    package var title: String {
        switch self {
        case .friendly: return "Friendly"
        case .persistent: return "Persistent"
        case .strict: return "Strict"
        }
    }

    package var detail: String {
        switch self {
        case .friendly: return "Pops up again after each snooze."
        case .persistent: return "After one snooze it stays on top, shakes, and has no close button."
        case .strict: return "Stays on top after one snooze. After two snoozes it locks the screen until you hold to confirm."
        }
    }
}
