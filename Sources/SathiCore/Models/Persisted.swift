import Foundation

package struct Persisted: Codable, Equatable, Sendable {
    package var prefs = Prefs()
    package var drinks: [DrinkEntry] = []
    package var reads: [ReadEntry] = []
    package var bottleLevel: Double = 1
    package var lastWaterDone: Date?
    package var streakReset: [String: Date] = [:]

    package init() {}
}
