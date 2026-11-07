import Foundation

package enum BreathingStyle: String, Codable, CaseIterable, Sendable {
    case calm, box, relax, even
}

package struct MeditationPrefs: Codable, Equatable, Sendable {
    package var enabled = false
    package var dailyGoalMinutes = 10
    package var sessionMinutes = 2
    package var intervalMinutes = 60
    package var startMinutes = Limits.meditationStartMinutes
    package var endMinutes = Limits.meditationEndMinutes
    package var style: BreathingStyle = .calm
    package var chime = true
    package var strictness: Strictness = .friendly
    package var weekdays: Set<Weekday> = Set(Weekday.allCases)
    package var daysOff: Set<DayKey> = []
    package var showsCloseButton = true

    package init() {}

    enum CodingKeys: String, CodingKey {
        case enabled, dailyGoalMinutes, sessionMinutes, intervalMinutes, startMinutes, endMinutes, style, chime, strictness
        case weekdays, daysOff, showsCloseButton
    }

    package var sortedWeekdays: [Weekday] {
        Weekday.allCases.filter(weekdays.contains)
    }
}

extension MeditationPrefs {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = MeditationPrefs()
        enabled = try c.value(.enabled, or: d.enabled)
        sessionMinutes = try c.value(.sessionMinutes, or: d.sessionMinutes)
        dailyGoalMinutes = try c.value(.dailyGoalMinutes, or: Self.legacyGoal(decoder, session: sessionMinutes) ?? d.dailyGoalMinutes)
        intervalMinutes = try ReminderInterval.nearest(c.value(.intervalMinutes, or: d.intervalMinutes))
        startMinutes = try c.value(.startMinutes, or: d.startMinutes)
        endMinutes = try c.value(.endMinutes, or: d.endMinutes)
        style = try c.known(.style, or: d.style)
        chime = try c.value(.chime, or: d.chime)
        strictness = try c.known(.strictness, or: d.strictness)
        showsCloseButton = try c.value(.showsCloseButton, or: d.showsCloseButton)
        weekdays = try c.knownSet(.weekdays, or: d.weekdays, keepsEmpty: false)
        daysOff = c.lenientSet(.daysOff, or: d.daysOff)
    }

    package func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(enabled, forKey: .enabled)
        try c.encode(dailyGoalMinutes, forKey: .dailyGoalMinutes)
        try c.encode(sessionMinutes, forKey: .sessionMinutes)
        try c.encode(intervalMinutes, forKey: .intervalMinutes)
        try c.encode(startMinutes, forKey: .startMinutes)
        try c.encode(endMinutes, forKey: .endMinutes)
        try c.encode(style, forKey: .style)
        try c.encode(chime, forKey: .chime)
        try c.encode(strictness, forKey: .strictness)
        try c.encode(showsCloseButton, forKey: .showsCloseButton)
        try c.encode(sortedWeekdays, forKey: .weekdays)
        try c.encode(daysOff.sorted(), forKey: .daysOff)
    }
}

extension MeditationPrefs {
    private enum LegacyKeys: String, CodingKey {
        case slots
    }

    private static let legacySlotNames: Set = ["morning", "afternoon", "evening"]

    static func legacyGoal(_ decoder: Decoder, session: Int) -> Int? {
        guard let c = try? decoder.container(keyedBy: LegacyKeys.self),
              let slots = try? c.decodeIfPresent([String].self, forKey: .slots) else { return nil }
        return session * max(1, Set(slots).intersection(legacySlotNames).count)
    }
}
