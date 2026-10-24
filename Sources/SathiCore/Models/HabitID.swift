import Foundation

package enum HabitID: String, Codable, CaseIterable, Identifiable, Sendable {
    case water, reading

    package var id: String { rawValue }

    package var name: String {
        switch self {
        case .water: return "Water"
        case .reading: return "Reading"
        }
    }

    package var buddy: String {
        switch self {
        case .water: return "Fota"
        case .reading: return "Boi"
        }
    }
}
