import Foundation

package struct WaterPrefs: Codable, Equatable, Sendable {
    package var enabled = true
    package var intervalMinutes = 120
    package var startMinutes = 9 * 60 + 30
    package var endMinutes = 18 * 60 + 30
    package var strictness: Strictness = .strict
    package var container: Container = .glass
    package var bottleSizeGlasses: Double = 3
    package var dailyGoalGlasses: Double = 8
    package var weekdays: Set<Weekday> = Set(Weekday.allCases)
    package var daysOff: Set<DayKey> = []
    package var showsCloseButton = true

    package init() {}

    enum CodingKeys: String, CodingKey {
        case enabled, intervalMinutes, startMinutes, endMinutes, strictness, container
        case bottleSizeGlasses, dailyGoalGlasses, weekdays, daysOff, showsCloseButton
    }

    package var sortedWeekdays: [Weekday] {
        Weekday.allCases.filter(weekdays.contains)
    }
}

extension WaterPrefs {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = WaterPrefs()
        enabled = try c.value(.enabled, or: d.enabled)
        intervalMinutes = try ReminderInterval.nearest(c.value(.intervalMinutes, or: d.intervalMinutes))
        startMinutes = try c.value(.startMinutes, or: d.startMinutes)
        endMinutes = try c.value(.endMinutes, or: d.endMinutes)
        strictness = try c.known(.strictness, or: d.strictness)
        showsCloseButton = try c.value(.showsCloseButton, or: d.showsCloseButton)
        container = try c.known(.container, or: d.container)
        bottleSizeGlasses = try c.value(.bottleSizeGlasses, or: d.bottleSizeGlasses)
        dailyGoalGlasses = try c.value(.dailyGoalGlasses, or: d.dailyGoalGlasses)
        weekdays = try c.knownSet(.weekdays, or: d.weekdays, keepsEmpty: false)
        daysOff = c.lenientSet(.daysOff, or: d.daysOff)
    }

    package func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(enabled, forKey: .enabled)
        try c.encode(intervalMinutes, forKey: .intervalMinutes)
        try c.encode(startMinutes, forKey: .startMinutes)
        try c.encode(endMinutes, forKey: .endMinutes)
        try c.encode(strictness, forKey: .strictness)
        try c.encode(showsCloseButton, forKey: .showsCloseButton)
        try c.encode(container, forKey: .container)
        try c.encode(bottleSizeGlasses, forKey: .bottleSizeGlasses)
        try c.encode(dailyGoalGlasses, forKey: .dailyGoalGlasses)
        try c.encode(sortedWeekdays, forKey: .weekdays)
        try c.encode(daysOff.sorted(), forKey: .daysOff)
    }
}
