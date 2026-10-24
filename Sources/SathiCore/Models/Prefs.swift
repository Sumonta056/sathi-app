import Foundation

package struct Prefs: Codable, Equatable, Sendable {
    package var general = GeneralPrefs()
    package var water = WaterPrefs()
    package var reading = ReadingPrefs()

    package init() {}

    package var scheduleKey: String {
        [
            "\(water.enabled)", "\(water.intervalMinutes)", "\(water.startMinutes)", "\(water.endMinutes)",
            "\(reading.enabled)", "\(reading.timeMinutes)", "\(reading.sessionMinutes)"
        ].joined(separator: "-")
    }

    package func isEnabled(_ id: HabitID) -> Bool {
        switch id {
        case .water: return water.enabled
        case .reading: return reading.enabled
        }
    }

    package func strictness(_ id: HabitID) -> Strictness {
        switch id {
        case .water: return water.strictness
        case .reading: return reading.strictness
        }
    }
}

extension Prefs {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Prefs()
        general = try c.value(.general, or: d.general)
        water = try c.value(.water, or: d.water)
        reading = try c.value(.reading, or: d.reading)
    }
}
