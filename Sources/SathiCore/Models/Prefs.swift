import Foundation

package struct Prefs: Codable, Equatable, Sendable {
    package var general = GeneralPrefs()
    package var water = WaterPrefs()
    package var reading = ReadingPrefs()
    package var meditation = MeditationPrefs()
    package var gym = GymPrefs()

    package init() {}

    package var scheduleKey: String {
        [
            "\(water.enabled)", "\(water.intervalMinutes)", "\(water.startMinutes)", "\(water.endMinutes)",
            "\(reading.enabled)", "\(reading.timeMinutes)", "\(reading.sessionMinutes)",
            "\(meditation.enabled)", "\(meditation.dailyGoalMinutes)", "\(meditation.sessionMinutes)",
            "\(meditation.intervalMinutes)", "\(meditation.startMinutes)", "\(meditation.endMinutes)",
            "\(gym.enabled)", "\(gym.intervalMinutes)", "\(gym.startMinutes)", "\(gym.endMinutes)"
        ].joined(separator: "-") + "|" + HabitID.allCases.map { Self.key(days($0)) }.joined(separator: "|")
    }

    package func days(_ id: HabitID) -> HabitDays {
        switch id {
        case .water: return HabitDays(weekdays: water.weekdays, daysOff: water.daysOff)
        case .reading: return HabitDays(weekdays: reading.weekdays, daysOff: reading.daysOff)
        case .meditation: return HabitDays(weekdays: meditation.weekdays, daysOff: meditation.daysOff)
        case .gym: return HabitDays(weekdays: gym.weekdays, daysOff: gym.daysOff)
        }
    }

    private static func key(_ d: HabitDays) -> String {
        let weekdays = Weekday.allCases.filter(d.weekdays.contains).map { "\($0.rawValue)" }
        return weekdays.joined(separator: "+") + "/" + d.daysOff.sorted().map(\.raw).joined(separator: "+")
    }

    package func isEnabled(_ id: HabitID) -> Bool {
        switch id {
        case .water: return water.enabled
        case .reading: return reading.enabled
        case .meditation: return meditation.enabled
        case .gym: return gym.enabled
        }
    }

    package func strictness(_ id: HabitID) -> Strictness {
        switch id {
        case .water: return water.strictness
        case .reading: return Self.withoutLock(reading.strictness)
        case .meditation: return meditation.strictness
        case .gym: return Self.withoutLock(gym.strictness)
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
        gym = try c.value(.gym, or: d.gym)
    }
}
