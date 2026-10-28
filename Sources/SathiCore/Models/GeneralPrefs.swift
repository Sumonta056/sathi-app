import Foundation

package struct GeneralPrefs: Codable, Equatable, Sendable {
    package var name = "Mridul"
    package var snoozeMinutes = 5
    package var ignoreMinutes = 5
    package var snoozeLimit: Int?
    package var soundOn = true
    package var daySummaryOn = true
    package var daySummaryMinutes = Limits.daySummaryMinutes

    package init() {}
}

extension GeneralPrefs {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = GeneralPrefs()
        name = try c.value(.name, or: d.name)
        snoozeMinutes = try c.value(.snoozeMinutes, or: d.snoozeMinutes)
        ignoreMinutes = try c.value(.ignoreMinutes, or: d.ignoreMinutes)
        snoozeLimit = c.lenient(.snoozeLimit, or: d.snoozeLimit).map(Self.clampedLimit)
        soundOn = try c.value(.soundOn, or: d.soundOn)
        daySummaryOn = c.lenient(.daySummaryOn, or: d.daySummaryOn)
        daySummaryMinutes = Self.validTime(c.lenient(.daySummaryMinutes, or: d.daySummaryMinutes), or: d.daySummaryMinutes)
    }

    private static func validTime(_ minutes: Int, or fallback: Int) -> Int {
        (0 ..< Limits.minutesPerDay).contains(minutes) && minutes % Limits.scheduleSlotMinutes == 0 ? minutes : fallback
    }

    private static func clampedLimit(_ n: Int) -> Int {
        min(max(n, Limits.snoozeLimits.lowerBound), Limits.snoozeLimits.upperBound)
    }
}
