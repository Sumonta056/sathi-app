import SathiCore
import SwiftUI

struct BreathTint: Equatable {
    var main: RGB
    var accent: RGB
}

enum BreathMood {
    private static let calm = RGB(hex: NightHex.calm)
    private static let water = RGB(hex: NightHex.water)
    private static let cheek = RGB(hex: NightHex.cheek)
    private static let spark = RGB(hex: NightHex.spark)
    private static let ground = RGB(hex: NightHex.calmGround)
    private static let muted = RGB(hex: NightHex.muted)

    static func target(_ phase: BreathPhase) -> BreathTint {
        let m = UIMetrics.self
        switch phase {
        case .inhale: return BreathTint(main: calm.mix(water, m.breathInhaleMain), accent: water)
        case .hold: return BreathTint(main: calm.mix(cheek, m.breathHoldMain), accent: cheek.mix(spark, m.breathHoldAccent))
        case .exhale: return BreathTint(main: calm.mix(ground, m.breathExhaleMain), accent: calm)
        case .rest: return BreathTint(main: calm.mix(ground, m.breathRestMain), accent: muted.mix(ground, m.breathRestAccent))
        }
    }

    static func blended(phase: BreathPhase, previous: BreathPhase, since: TimeInterval) -> BreathTint {
        let p = min(1, max(0, since / UIMetrics.breathMoodBlend))
        let eased = p * p * (3 - 2 * p)
        let from = target(previous)
        let to = target(phase)
        return BreathTint(main: from.main.mix(to.main, eased), accent: from.accent.mix(to.accent, eased))
    }

    static func tint(_ style: BreathingStyle, elapsed: TimeInterval) -> BreathTint {
        let steps = BreathingPattern.steps(style).map(\.0)
        let (step, length) = BreathMotion.into(style, elapsed: elapsed)
        let i = steps.firstIndex(of: step.phase) ?? 0
        let firstEver = step.cycle == 0 && i == 0
        let previous = firstEver ? step.phase : steps[(i + steps.count - 1) % steps.count]
        return blended(phase: step.phase, previous: previous, since: length - step.remaining)
    }
}
