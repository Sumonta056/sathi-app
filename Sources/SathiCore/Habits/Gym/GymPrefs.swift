import Foundation

package struct GymPrefs: Codable, Equatable, Sendable {
    package var enabled = false
    package var intervalMinutes = 60
    package var startMinutes = Limits.gymStartMinutes
    package var endMinutes = Limits.gymEndMinutes
    package var weekdays: Set<Weekday> = Set(Weekday.allCases)
    package var daysOff: Set<DayKey> = []
    package var workouts = GymWorkout.defaults
    package var strictness: Strictness = .friendly
    package var showsCloseButton = true

    package init() {}

    enum CodingKeys: String, CodingKey {
        case enabled, intervalMinutes, startMinutes, endMinutes, weekdays, daysOff, workouts, strictness, showsCloseButton
    }

    package var sortedWeekdays: [Weekday] {
        Weekday.allCases.filter(weekdays.contains)
    }

    package func workout(at index: Int) -> GymWorkout {
        let count = Limits.gymWorkoutCount
        return Self.cleaned(workouts)[((index % count) + count) % count]
    }

    package static func cleaned(_ workouts: [GymWorkout]) -> [GymWorkout] {
        let defaults = GymWorkout.defaults
        return (0 ..< Limits.gymWorkoutCount).map { i in
            guard i < workouts.count else { return defaults[i] }
            let row = workouts[i]
            let trimmed = row.name.trimmingCharacters(in: .whitespacesAndNewlines)
            return GymWorkout(
                name: trimmed.isEmpty ? defaults[i].name : String(trimmed.prefix(Limits.gymNameMaxLength)),
                minutes: Limits.gymWorkoutLengths.contains(row.minutes) ? row.minutes : defaults[i].minutes
            )
        }
    }
}

extension GymPrefs {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = GymPrefs()
        enabled = try c.value(.enabled, or: d.enabled)
        intervalMinutes = try ReminderInterval.nearest(c.value(.intervalMinutes, or: d.intervalMinutes))
        startMinutes = try c.value(.startMinutes, or: d.startMinutes)
        endMinutes = try c.value(.endMinutes, or: d.endMinutes)
        weekdays = try c.knownSet(.weekdays, or: d.weekdays, keepsEmpty: false)
        daysOff = c.lenientSet(.daysOff, or: d.daysOff)
        workouts = try Self.cleaned(c.value(.workouts, or: d.workouts))
        strictness = try Strictness.upgraded(c.known(.strictness, or: d.strictness), oldFile: !c.contains(.showsCloseButton))
        showsCloseButton = try c.value(.showsCloseButton, or: d.showsCloseButton)
    }

    package func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(enabled, forKey: .enabled)
        try c.encode(intervalMinutes, forKey: .intervalMinutes)
        try c.encode(startMinutes, forKey: .startMinutes)
        try c.encode(endMinutes, forKey: .endMinutes)
        try c.encode(sortedWeekdays, forKey: .weekdays)
        try c.encode(daysOff.sorted(), forKey: .daysOff)
        try c.encode(workouts, forKey: .workouts)
        try c.encode(strictness, forKey: .strictness)
        try c.encode(showsCloseButton, forKey: .showsCloseButton)
    }
}
