import Foundation

extension Copywriter {
    package static func meditationInviteHint(minutes: Int, style: BreathingStyle) -> String {
        "\(minutes) \(minutes == 1 ? "minute" : "minutes") of \(breathName(style)). Shanti counts for you."
    }

    package static func breathHeader(_ style: BreathingStyle) -> String {
        "\(breathTitle(style)) · \(breathBeats(style))"
    }

    package static func breathBeats(_ style: BreathingStyle) -> String {
        BreathingPattern.steps(style).map { "\(Int($0.1))" }.joined(separator: "·")
    }

    package static func breathRound(_ round: Int, of total: Int) -> String {
        "Round \(round) of \(total)"
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
        case .box: "box breathing"
        case .relax: "wind-down breathing"
        case .even: "even breathing"
        }
    }

    private static func breathTitle(_ style: BreathingStyle) -> String {
        switch style {
        case .box: "BOX BREATHING"
        case .relax: "WIND DOWN"
        case .even: "EVEN BREATHING"
        }
    }
}
