import SathiCore
import Testing

@Suite("Breath copy")
struct BreathCopyTests {
    @Test(arguments: [
        (5, BreathingStyle.box, "5 minutes of box breathing. Shanti counts for you."),
        (1, .even, "1 minute of even breathing. Shanti counts for you."),
        (10, .relax, "10 minutes of wind-down breathing. Shanti counts for you.")
    ])
    func inviteHint(_ minutes: Int, _ style: BreathingStyle, _ expected: String) {
        #expect(Copywriter.meditationInviteHint(minutes: minutes, style: style) == expected)
    }

    @Test(arguments: [
        (BreathingStyle.box, "BOX BREATHING · 4·4·4·4"),
        (.relax, "WIND DOWN · 4·7·8"),
        (.even, "EVEN BREATHING · 5·5")
    ])
    func header(_ style: BreathingStyle, _ expected: String) {
        #expect(Copywriter.breathHeader(style) == expected)
    }

    @Test func roundCounter() {
        #expect(Copywriter.breathRound(3, of: 18) == "Round 3 of 18")
    }

    @Test(arguments: [(4, "4 calm days in a row."), (2, "2 calm days in a row."), (1, "A calm start."), (0, "A calm start.")])
    func thanksHint(_ streak: Int, _ expected: String) {
        #expect(Copywriter.calmThanksHint(streak: streak) == expected)
    }

    @Test(arguments: [
        (BreathPhase.inhale, "Breathe in"),
        (.hold, "Hold"),
        (.exhale, "Breathe out"),
        (.rest, "Rest")
    ])
    func phaseLabel(_ phase: BreathPhase, _ expected: String) {
        #expect(Copywriter.breathLabel(phase) == expected)
    }
}
