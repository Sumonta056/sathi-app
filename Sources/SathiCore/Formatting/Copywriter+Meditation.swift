import Foundation

extension Copywriter {
    package static func meditationInviteHint(minutes: Int, style: BreathingStyle) -> String {
        "\(minutes) \(minutes == 1 ? "minute" : "minutes") of \(breathName(style)). Shanti counts for you."
    }

    package static func breathBeats(_ style: BreathingStyle) -> String {
        BreathingPattern.steps(style).map { "\(Int($0.1))" }.joined(separator: "·")
    }

    package static func breathEyebrow(_ style: BreathingStyle) -> String {
        let beats = BreathingPattern.steps(style).map { "\(Int($0.1))" }.joined(separator: " ")
        return "\(breathShortName(style).uppercased()) · \(beats)"
    }

    package static func breathCount(_ n: Int, _ phase: BreathPhase) -> String {
        let word: String = switch phase {
        case .inhale: "IN"
        case .hold: "HOLD"
        case .exhale: "OUT"
        case .rest: "REST"
        }
        return "\(n) · \(word)"
    }

    package static func breathLeft(_ remaining: TimeInterval) -> String {
        "\(Fmt.clock(remaining)) left"
    }

    package static func breathVoice(_ cue: BreathCue) -> String {
        switch cue {
        case .begin: "Let's begin"
        case .inhale: "Breathe in"
        case .hold: "Hold"
        case .exhale: "Breathe out"
        case .rest: "Rest"
        case .wellDone: "Well done"
        }
    }

    package static func breathShortName(_ style: BreathingStyle) -> String {
        switch style {
        case .calm: "Calm"
        case .box: "Box"
        case .relax: "Wind down"
        case .even: "Even"
        }
    }

    package static func calmThanksHint(streak: Int) -> String {
        streak >= 2 ? "\(streak) calm days in a row." : "A calm start."
    }

    package static func breathLabel(_ phase: BreathPhase) -> String {
        switch phase {
        case .inhale: "Breathe in"
        case .hold: "Hold"
        case .exhale: "Breathe out"
        case .rest: "Rest"
        }
    }

    private static func breathName(_ style: BreathingStyle) -> String {
        switch style {
        case .calm: "calm breathing"
        case .box: "box breathing"
        case .relax: "wind-down breathing"
        case .even: "even breathing"
        }
    }
}
