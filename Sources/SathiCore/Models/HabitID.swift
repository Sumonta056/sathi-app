import Foundation

package enum HabitID: String, Codable, CaseIterable, Identifiable, Sendable {
    case water, reading

    package var id: String { rawValue }
    package var name: String { self == .water ? "Water" : "Reading" }
    package var buddy: String { self == .water ? "Fota" : "Boi" }
}
