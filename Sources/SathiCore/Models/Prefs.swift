import Foundation

package struct Prefs: Codable, Equatable, Sendable {
    package var general = GeneralPrefs()
    package var water = WaterPrefs()
    package var reading = ReadingPrefs()
    package var meditation = MeditationPrefs()
    package var gym = GymPrefs()
    package var quick = QuickPrefs()
    package var timeBlock = TimeBlockPrefs()

    package init() {}

    package var scheduleKey: String {
        HabitID.allCases.map(scheduleKey).joined(separator: "|")
    }

    package func scheduleKey(_ id: HabitID) -> String {
        let values: [String] = switch id {
        case .water: ["\(water.enabled)", "\(water.intervalMinutes)", "\(water.startMinutes)", "\(water.endMinutes)"]
        case .reading: ["\(reading.enabled)", "\(reading.timeMinutes)", "\(reading.sessionMinutes)"]
        case .meditation: [
                "\(meditation.enabled)", "\(meditation.dailyGoalMinutes)", "\(meditation.sessionMinutes)",
                "\(meditation.intervalMinutes)", "\(meditation.startMinutes)", "\(meditation.endMinutes)"
            ]
        case .gym: ["\(gym.enabled)", "\(gym.sessionsPerDay)", "\(gym.sessionMinutes)", "\(gym.startMinutes)", "\(gym.endMinutes)"]
        }
        return values.joined(separator: "-") + "/" + Self.key(days(id))
    }

    package func days(_ id: HabitID) -> HabitDays {
        switch id {
        case .water: return HabitDays(weekdays: water.weekdays, daysOff: water.daysOff)
        case .reading: return HabitDays(weekdays: reading.weekdays, daysOff: reading.daysOff)
        case .meditation: return HabitDays(weekdays: meditation.weekdays, daysOff: meditation.daysOff)
        case .gym: return HabitDays(weekdays: gym.weekdays, daysOff: gym.daysOff)
        }
    }

    package mutating func setDays(_ id: HabitID, _ d: HabitDays) {
        switch id {
        case .water: (water.weekdays, water.daysOff) = (d.weekdays, d.daysOff)
        case .reading: (reading.weekdays, reading.daysOff) = (d.weekdays, d.daysOff)
        case .meditation: (meditation.weekdays, meditation.daysOff) = (d.weekdays, d.daysOff)
        case .gym: (gym.weekdays, gym.daysOff) = (d.weekdays, d.daysOff)
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
        case .reading: return reading.strictness
        case .meditation: return meditation.strictness
        case .gym: return gym.strictness
        }
    }

    package func showsCloseButton(_ id: HabitID) -> Bool {
        switch id {
        case .water: return water.showsCloseButton
        case .reading: return reading.showsCloseButton
        case .meditation: return meditation.showsCloseButton
        case .gym: return gym.showsCloseButton
        }
    }

    package mutating func setShowsCloseButton(_ id: HabitID, _ on: Bool) {
        switch id {
        case .water: water.showsCloseButton = on
        case .reading: reading.showsCloseButton = on
        case .meditation: meditation.showsCloseButton = on
        case .gym: gym.showsCloseButton = on
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
        meditation = try c.value(.meditation, or: d.meditation)
        gym = try c.value(.gym, or: d.gym)
        quick = c.lenient(.quick, or: d.quick)
        timeBlock = c.lenient(.timeBlock, or: d.timeBlock)
    }
}
