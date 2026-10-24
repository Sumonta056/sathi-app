import Foundation

package struct Persisted: Codable, Equatable, Sendable {
    package var prefs = Prefs()
    package var drinks: [DrinkEntry] = []
    package var reads: [ReadEntry] = []
    package var bottleLevel: Double = 1
    package var lastWaterDone: Date?
    package var streakReset: [String: Date] = [:]

    package init() {}

    package func lastDone(_ id: HabitID) -> Date? {
        switch id {
        case .water: return lastWaterDone
        case .reading: return nil
        }
    }
}
