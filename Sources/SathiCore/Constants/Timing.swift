import Foundation

package enum Timing {
    package static let minute: TimeInterval = 60
    package static let hour: TimeInterval = 3600
    package static let day: TimeInterval = 86400

    package static let activeTick: TimeInterval = 1
    package static let idleTickMax: TimeInterval = 60
    package static let minTick: TimeInterval = 0.25
    package static let minuteEdgePadding: TimeInterval = 0.05
    package static let tickToleranceRatio = 0.1
    package static let maxTickTolerance: TimeInterval = 2

    package static let celebrationDuration: TimeInterval = 4.5
    package static let lockHoldDuration: TimeInterval = 3
    package static let lockConfirmDelay: TimeInterval = 0.45
    package static let defaultPauseHours: Double = 1
}
