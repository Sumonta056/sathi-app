import Foundation

package struct GymPrefs: Codable, Equatable, Sendable {
    package var enabled = false
    package var sessionsPerDay = Limits.gymDefaultSessions
    package var sessionMinutes = Limits.gymDefaultSessionMinutes
    package var startMinutes = Limits.gymStartMinutes
    package var endMinutes = Limits.gymEndMinutes
    package var weekdays: Set<Weekday> = Set(Weekday.allCases)
    package var daysOff: Set<DayKey> = []
    package var ideas = GymIdeas.defaults
    package var strictness: Strictness = .friendly
    package var showsCloseButton = true

    package init() {}

    enum CodingKeys: String, CodingKey {
        case enabled, sessionsPerDay, sessionMinutes, startMinutes, endMinutes, weekdays, daysOff, ideas, workouts
        case strictness, showsCloseButton
    }

    package var dailyGoalMinutes: Int { sessionsPerDay * sessionMinutes }

    package var popupMinutes: [Int] {
        guard startMinutes < endMinutes else { return [] }
        let span = endMinutes - startMinutes
        return (0 ..< sessionsPerDay).map { startMinutes + span * (2 * $0 + 1) / (2 * sessionsPerDay) }
    }

    package var sortedWeekdays: [Weekday] {
        Weekday.allCases.filter(weekdays.contains)
    }

    package func idea(at index: Int) -> String {
        let list = GymIdeas.cleaned(ideas)
        return list[((index % list.count) + list.count) % list.count]
    }
}

extension GymPrefs {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = GymPrefs()
        enabled = try c.value(.enabled, or: d.enabled)
        sessionsPerDay = try ReminderInterval.nearest(c.value(.sessionsPerDay, or: d.sessionsPerDay), in: Limits.gymSessionCounts)
        sessionMinutes = try ReminderInterval.nearest(c.value(.sessionMinutes, or: d.sessionMinutes), in: Limits.gymSessionLengths)
        startMinutes = try c.value(.startMinutes, or: d.startMinutes)
        endMinutes = try c.value(.endMinutes, or: d.endMinutes)
        weekdays = try c.knownSet(.weekdays, or: d.weekdays, keepsEmpty: false)
        daysOff = c.lenientSet(.daysOff, or: d.daysOff)
        ideas = GymIdeas.cleaned(Self.savedIdeas(c))
        strictness = try Strictness.upgraded(c.known(.strictness, or: d.strictness), oldFile: !c.contains(.showsCloseButton))
        showsCloseButton = try c.value(.showsCloseButton, or: d.showsCloseButton)
    }

    private static func savedIdeas(_ c: KeyedDecodingContainer<CodingKeys>) -> [String] {
        if c.contains(.ideas) { return c.lenientArray(.ideas) }
        return (c.lenientArray(.workouts) as [LegacyGymWorkout]).map(\.name)
    }

    package func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(enabled, forKey: .enabled)
        try c.encode(sessionsPerDay, forKey: .sessionsPerDay)
        try c.encode(sessionMinutes, forKey: .sessionMinutes)
        try c.encode(startMinutes, forKey: .startMinutes)
        try c.encode(endMinutes, forKey: .endMinutes)
        try c.encode(sortedWeekdays, forKey: .weekdays)
        try c.encode(daysOff.sorted(), forKey: .daysOff)
        try c.encode(GymIdeas.cleaned(ideas), forKey: .ideas)
        try c.encode(strictness, forKey: .strictness)
        try c.encode(showsCloseButton, forKey: .showsCloseButton)
    }
}
