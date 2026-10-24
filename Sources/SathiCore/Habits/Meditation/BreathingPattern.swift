import Foundation

package enum BreathPhase: String, Sendable {
    case inhale, hold, exhale, rest
}

package struct BreathStep: Equatable, Sendable {
    package var phase: BreathPhase
    package var remaining: TimeInterval
    package var cycle: Int

    package init(phase: BreathPhase, remaining: TimeInterval, cycle: Int) {
        self.phase = phase
        self.remaining = remaining
        self.cycle = cycle
    }
}

package enum BreathingPattern {
    package static func steps(_ style: BreathingStyle) -> [(BreathPhase, TimeInterval)] {
        switch style {
        case .box:
            return [(.inhale, Timing.breathBox), (.hold, Timing.breathBox), (.exhale, Timing.breathBox), (.rest, Timing.breathBox)]
        case .relax:
            return [(.inhale, Timing.breathRelaxIn), (.hold, Timing.breathRelaxHold), (.exhale, Timing.breathRelaxOut)]
        case .even:
            return [(.inhale, Timing.breathEven), (.exhale, Timing.breathEven)]
        }
    }

    package static func cycleLength(_ style: BreathingStyle) -> TimeInterval {
        steps(style).reduce(0) { $0 + $1.1 }
    }

    package static func step(_ style: BreathingStyle, at elapsed: TimeInterval) -> BreathStep {
        let all = steps(style)
        let length = cycleLength(style)
        let t = max(0, elapsed)
        let cycle = Int((t / length).rounded(.down))
        var offset = t - Double(cycle) * length
        for (phase, duration) in all {
            if offset < duration { return BreathStep(phase: phase, remaining: duration - offset, cycle: cycle) }
            offset -= duration
        }
        let first = all[0]
        return BreathStep(phase: first.0, remaining: first.1, cycle: cycle + 1)
    }

    package static func totalRounds(_ style: BreathingStyle, minutes: Int) -> Int {
        max(1, Int((Double(minutes) * Timing.minute / cycleLength(style)).rounded(.down)))
    }

    package static func round(_ style: BreathingStyle, elapsed: TimeInterval, minutes: Int) -> Int {
        min(step(style, at: elapsed).cycle + 1, totalRounds(style, minutes: minutes))
    }
}
