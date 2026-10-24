import Foundation

package enum Limits {
    package static let monthsInMemory = 3
    package static let schemaVersion = 1
    package static let streakLookbackDays = 365

    package static let glassStep: Double = 0.25
    package static let minimumLog: Double = 0.25
    package static let minimumBottleDrink: Double = 0.12
    package static let lowWaterLevel: Double = 0.25
    package static let statusIconSteps: Double = 20
    package static let absoluteTimeThreshold: TimeInterval = 3 * Timing.hour

    package static let minutesPerDay = 24 * 60
    package static let scheduleSlotMinutes = 30

    package static let waterIntervalMinutes = 15 ... 240
    package static let waterIntervalStep = 15
    package static let bottleSizeGlasses: ClosedRange<Double> = 1 ... 6
    package static let bottleSizeStep: Double = 0.5
    package static let dailyGoalGlasses: ClosedRange<Double> = 4 ... 16
    package static let snoozeMinutes = 1 ... 30
    package static let ignoreMinutes = 1 ... 15
    package static let sessionLengths = [10, 15, 20, 30, 45, 60]
    package static let meditationLengths = [2, 5, 10]
    package static let morningSlotMinutes = 8 * 60
    package static let afternoonSlotMinutes = 14 * 60
    package static let eveningSlotMinutes = 21 * 60 + 30
}
