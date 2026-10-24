import Foundation

package struct Prefs: Codable, Equatable, Sendable {
    package var name = "Mridul"

    package var waterEnabled = true
    package var waterIntervalMinutes = 120
    package var waterStartMinutes = 9 * 60 + 30
    package var waterEndMinutes = 18 * 60 + 30
    package var waterStrictness: Strictness = .strict
    package var defaultContainer: Container = .glass
    package var bottleSizeGlasses: Double = 3
    package var dailyGoalGlasses: Double = 8

    package var readingEnabled = true
    package var readingTimeMinutes = 22 * 60
    package var readingSessionMinutes = 15
    package var readingStrictness: Strictness = .persistent

    package var snoozeMinutes = 5
    package var ignoreMinutes = 5
    package var soundOn = true

    package init() {}

    package var scheduleKey: String {
        [
            "\(waterEnabled)", "\(waterIntervalMinutes)", "\(waterStartMinutes)", "\(waterEndMinutes)",
            "\(readingEnabled)", "\(readingTimeMinutes)", "\(readingSessionMinutes)"
        ].joined(separator: "-")
    }

    package func isEnabled(_ id: HabitID) -> Bool {
        id == .water ? waterEnabled : readingEnabled
    }

    package func strictness(_ id: HabitID) -> Strictness {
        id == .water ? waterStrictness : readingStrictness
    }
}
