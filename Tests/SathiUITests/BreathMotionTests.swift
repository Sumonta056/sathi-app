import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import Testing

@MainActor
@Suite("Breath motion")
struct BreathMotionTests {
    private func near(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 0.0001 }

    @Test func calmOpennessStartsClosed() {
        #expect(near(BreathMotion.openness(.calm, elapsed: 0), 0))
    }

    @Test func calmOpennessIsHalfMidInhale() {
        #expect(near(BreathMotion.openness(.calm, elapsed: 2), 0.5))
    }

    @Test func boxOpennessIsFullDuringHold() {
        #expect(near(BreathMotion.openness(.box, elapsed: 6), 1))
    }

    @Test func relaxOpennessIsHalfMidExhale() {
        #expect(near(BreathMotion.openness(.relax, elapsed: 4 + 7 + 4), 0.5))
    }

    @Test func reduceMotionHoldsTheOrbStill() {
        for elapsed in [0.0, 2, 6, 9] {
            #expect(near(BreathMotion.openness(.calm, elapsed: elapsed, reduceMotion: true), 0.85))
        }
    }

    @Test(arguments: [
        (BreathScale.orb, 0.0, 0.72), (.orb, 1, 1),
        (.core, 0, 0.82), (.core, 1, 1),
        (.face, 0, 0.84), (.face, 1, 1.05)
    ])
    func scales(_ kind: BreathScale, _ open: Double, _ expected: Double) {
        #expect(near(BreathMotion.scale(open: open, kind), expected))
    }

    @Test func threeRipplesDuringAnInhale() {
        #expect(BreathMotion.ripples(.calm, elapsed: 2.5).count == 3)
    }

    @Test func noRipplesDuringAnExhale() {
        #expect(BreathMotion.ripples(.calm, elapsed: 6).isEmpty)
    }

    @Test func ripplesRunFromZeroToOne() {
        #expect(BreathMotion.ripples(.calm, elapsed: 2.5).allSatisfy { $0 > 0 && $0 < 1 })
    }

    @Test func blobsGrowWithTheOrbAndStepUp() {
        #expect(near(BreathMotion.blob(index: 0, t: 0, open: 1).scale, 1))
        #expect(near(BreathMotion.blob(index: 1, t: 0, open: 1).scale, 1.06))
        #expect(near(BreathMotion.blob(index: 0, t: 0, open: 0).scale, 0.72))
    }

    @Test func blobRadiiStayInsideTheSwing() {
        for t in stride(from: 0.0, to: 60, by: 0.7) {
            let b = BreathMotion.blob(index: 2, t: t, open: 0.5)
            #expect(b.radii.allSatisfy { $0 >= 0.38 - 0.0001 && $0 <= 0.62 + 0.0001 })
        }
    }

    @Test func progressFollowsElapsedOverTheLength() {
        let start = day(2026, 3, 4, 15)
        let s = Session(start: start, end: start.addingTimeInterval(300))
        #expect(near(BreathMotion.progress(session: s, at: start.addingTimeInterval(150)), 0.5))
        #expect(near(BreathMotion.progress(session: s, at: start.addingTimeInterval(900)), 1))
    }

    @Test func moodStartsFromThePreviousPhase() {
        let t = BreathMood.blended(phase: .exhale, previous: .inhale, since: 0)
        #expect(t == BreathMood.target(.inhale))
    }

    @Test func moodReachesTheNewPhaseAfterTheBlend() {
        let t = BreathMood.blended(phase: .exhale, previous: .inhale, since: UIMetrics.breathMoodBlend)
        #expect(t == BreathMood.target(.exhale))
    }

    @Test func moodIsBetweenColoursMidBlend() {
        let t = BreathMood.blended(phase: .exhale, previous: .inhale, since: UIMetrics.breathMoodBlend / 2)
        #expect(t != BreathMood.target(.inhale))
        #expect(t != BreathMood.target(.exhale))
    }

    @Test func inhaleMoodMixesCalmTowardWater() {
        let calm = SathiUI.RGB(hex: NightHex.calm)
        let water = SathiUI.RGB(hex: NightHex.water)
        #expect(BreathMood.target(.inhale) == BreathTint(main: calm.mix(water, 0.45), accent: water))
    }
}
