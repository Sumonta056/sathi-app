import Foundation

struct LegacyV1Prefs: Decodable {
    var name: String
    var waterEnabled: Bool
    var waterIntervalMinutes: Int
    var waterStartMinutes: Int
    var waterEndMinutes: Int
    var waterStrictness: Strictness
    var defaultContainer: Container
    var bottleSizeGlasses: Double
    var dailyGoalGlasses: Double
    var readingEnabled: Bool
    var readingTimeMinutes: Int
    var readingSessionMinutes: Int
    var readingStrictness: Strictness
    var snoozeMinutes: Int
    var ignoreMinutes: Int
    var soundOn: Bool

    init(from p: Prefs) {
        name = p.general.name
        waterEnabled = p.water.enabled
        waterIntervalMinutes = p.water.intervalMinutes
        waterStartMinutes = p.water.startMinutes
        waterEndMinutes = p.water.endMinutes
        waterStrictness = p.water.strictness
        defaultContainer = p.water.container
        bottleSizeGlasses = p.water.bottleSizeGlasses
        dailyGoalGlasses = p.water.dailyGoalGlasses
        readingEnabled = p.reading.enabled
        readingTimeMinutes = p.reading.timeMinutes
        readingSessionMinutes = p.reading.sessionMinutes
        readingStrictness = p.reading.strictness
        snoozeMinutes = p.general.snoozeMinutes
        ignoreMinutes = p.general.ignoreMinutes
        soundOn = p.general.soundOn
    }

    var prefs: Prefs {
        var p = Prefs()
        p.general.name = name
        p.general.snoozeMinutes = snoozeMinutes
        p.general.ignoreMinutes = ignoreMinutes
        p.general.soundOn = soundOn
        p.water.enabled = waterEnabled
        p.water.intervalMinutes = waterIntervalMinutes
        p.water.startMinutes = waterStartMinutes
        p.water.endMinutes = waterEndMinutes
        p.water.strictness = waterStrictness
        p.water.container = defaultContainer
        p.water.bottleSizeGlasses = bottleSizeGlasses
        p.water.dailyGoalGlasses = dailyGoalGlasses
        p.reading.enabled = readingEnabled
        p.reading.timeMinutes = readingTimeMinutes
        p.reading.sessionMinutes = readingSessionMinutes
        p.reading.strictness = readingStrictness
        return p
    }
}

extension LegacyV1Prefs {
    private enum CodingKeys: String, CodingKey {
        case name, waterEnabled, waterIntervalMinutes, waterStartMinutes, waterEndMinutes, waterStrictness
        case defaultContainer, bottleSizeGlasses, dailyGoalGlasses
        case readingEnabled, readingTimeMinutes, readingSessionMinutes, readingStrictness
        case snoozeMinutes, ignoreMinutes, soundOn
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = LegacyV1Prefs(from: Prefs())
        name = try c.value(.name, or: d.name)
        waterEnabled = try c.value(.waterEnabled, or: d.waterEnabled)
        waterIntervalMinutes = try c.value(.waterIntervalMinutes, or: d.waterIntervalMinutes)
        waterStartMinutes = try c.value(.waterStartMinutes, or: d.waterStartMinutes)
        waterEndMinutes = try c.value(.waterEndMinutes, or: d.waterEndMinutes)
        waterStrictness = try c.value(.waterStrictness, or: d.waterStrictness)
        defaultContainer = try c.value(.defaultContainer, or: d.defaultContainer)
        bottleSizeGlasses = try c.value(.bottleSizeGlasses, or: d.bottleSizeGlasses)
        dailyGoalGlasses = try c.value(.dailyGoalGlasses, or: d.dailyGoalGlasses)
        readingEnabled = try c.value(.readingEnabled, or: d.readingEnabled)
        readingTimeMinutes = try c.value(.readingTimeMinutes, or: d.readingTimeMinutes)
        readingSessionMinutes = try c.value(.readingSessionMinutes, or: d.readingSessionMinutes)
        readingStrictness = try c.value(.readingStrictness, or: d.readingStrictness)
        snoozeMinutes = try c.value(.snoozeMinutes, or: d.snoozeMinutes)
        ignoreMinutes = try c.value(.ignoreMinutes, or: d.ignoreMinutes)
        soundOn = try c.value(.soundOn, or: d.soundOn)
    }
}
