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

    package init() {}
}

extension WaterPrefs {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = WaterPrefs()
        enabled = try c.value(.enabled, or: d.enabled)
        intervalMinutes = try c.value(.intervalMinutes, or: d.intervalMinutes)
        startMinutes = try c.value(.startMinutes, or: d.startMinutes)
        endMinutes = try c.value(.endMinutes, or: d.endMinutes)
        strictness = try c.value(.strictness, or: d.strictness)
        container = try c.value(.container, or: d.container)
        bottleSizeGlasses = try c.value(.bottleSizeGlasses, or: d.bottleSizeGlasses)
        dailyGoalGlasses = try c.value(.dailyGoalGlasses, or: d.dailyGoalGlasses)
    }
}
