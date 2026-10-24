import Foundation

package enum TickPlanner {
    package static func delay(
        now: Date,
        phase: Phase,
        deadlines: [Date],
        focusRemaining: TimeInterval?
    ) -> TimeInterval {
        if case .session = phase { return Timing.activeTick }
        var delay = Timing.idleTickMax
        for deadline in deadlines {
            let wait = deadline.timeIntervalSince(now)
            if wait > 0 { delay = min(delay, wait) }
        }
        if let remaining = focusRemaining, remaining > 0 {
            let toLabelChange = remaining.truncatingRemainder(dividingBy: Timing.minute) + Timing.minuteEdgePadding
            delay = min(delay, toLabelChange)
        }
        return max(Timing.minTick, delay)
    }

    package static func tolerance(for delay: TimeInterval) -> TimeInterval {
        min(delay * Timing.tickToleranceRatio, Timing.maxTickTolerance)
    }
}
