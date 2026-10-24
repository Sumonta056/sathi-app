import Foundation

package enum HabitID: String, Codable, CaseIterable, Identifiable, Sendable {
    case water, reading, meditation

    package var id: String { rawValue }

    package var name: String {
        switch self {
        case .water: return "Water"
        case .reading: return "Reading"
        case .meditation: return "Meditation"
        }
    }

    package var buddy: String {
        switch self {
        case .water: return "Fota"
        case .reading: return "Boi"
        case .meditation: return "Shanti"
        }
    }
}
