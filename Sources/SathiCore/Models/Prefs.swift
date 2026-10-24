import Foundation

package struct Prefs: Codable, Equatable, Sendable {
    package var general = GeneralPrefs()
    package var water = WaterPrefs()
    package var reading = ReadingPrefs()
    package var meditation = MeditationPrefs()

    package init() {}

    package var scheduleKey: String {
        [
            "\(water.enabled)", "\(water.intervalMinutes)", "\(water.startMinutes)", "\(water.endMinutes)",
            "\(reading.enabled)", "\(reading.timeMinutes)", "\(reading.sessionMinutes)",
            reading.sortedWeekdays.map { "\($0.rawValue)" }.joined(separator: "+"),
            "\(meditation.enabled)", meditation.sortedSlots.map(\.rawValue).joined(separator: "+"), "\(meditation.sessionMinutes)"
        ].joined(separator: "-")
    }

    package func isEnabled(_ id: HabitID) -> Bool {
        switch id {
        case .water: return water.enabled
        case .reading: return reading.enabled
        case .meditation: return meditation.enabled
        }
    }

    package func strictness(_ id: HabitID) -> Strictness {
        switch id {
        case .water: return water.strictness
        case .reading: return Self.withoutLock(reading.strictness)
        case .meditation: return Self.withoutLock(meditation.strictness)
        }
    }

    private static func withoutLock(_ s: Strictness) -> Strictness {
        s == .strict ? .persistent : s
    }
}

extension Prefs {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Prefs()
        general = try c.value(.general, or: d.general)
        water = try c.value(.water, or: d.water)
        reading = try c.value(.reading, or: d.reading)
        meditation = try c.value(.meditation, or: d.meditation)
    }
}
