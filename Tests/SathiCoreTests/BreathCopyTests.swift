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

    @Test(arguments: [
        (BreathingStyle.calm, "CALM · 4 6"),
        (.box, "BOX · 4 4 4 4"),
        (.relax, "WIND DOWN · 4 7 8"),
        (.even, "EVEN · 5 5")
    ])
    func eyebrow(_ style: BreathingStyle, _ expected: String) {
        #expect(Copywriter.breathEyebrow(style) == expected)
    }

    @Test(arguments: [
        (4, BreathPhase.inhale, "4 · IN"),
        (3, .hold, "3 · HOLD"),
        (6, .exhale, "6 · OUT"),
        (1, .rest, "1 · REST")
    ])
    func count(_ n: Int, _ phase: BreathPhase, _ expected: String) {
        #expect(Copywriter.breathCount(n, phase) == expected)
    }

    @Test func left() {
        #expect(Copywriter.breathLeft(192) == "3:12 left")
    }

    @Test(arguments: [
        (BreathCue.begin, "Let's begin"),
        (.inhale, "Breathe in"),
        (.hold, "Hold"),
        (.exhale, "Breathe out"),
        (.rest, "Rest"),
        (.wellDone, "Well done")
    ])
    func voice(_ cue: BreathCue, _ expected: String) {
        #expect(Copywriter.breathVoice(cue) == expected)
    }

    @Test func calmInviteHint() {
        #expect(Copywriter.meditationInviteHint(minutes: 2, style: .calm).contains("calm breathing"))
    }

    @Test func shortNames() {
        #expect(BreathingStyle.allCases.map(Copywriter.breathShortName) == ["Calm", "Box", "Wind down", "Even"])
    }

    @Test func cueFollowsThePhase() {
        #expect(BreathCue(.inhale) == .inhale)
        #expect(BreathCue(.hold) == .hold)
        #expect(BreathCue(.exhale) == .exhale)
        #expect(BreathCue(.rest) == .rest)
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
