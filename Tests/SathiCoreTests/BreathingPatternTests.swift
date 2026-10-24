import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("BreathingPattern")
struct BreathingPatternTests {
    @Test(arguments: [
        (BreathingStyle.box, [BreathPhase.inhale, .hold, .exhale, .rest], [4.0, 4, 4, 4]),
        (BreathingStyle.relax, [BreathPhase.inhale, .hold, .exhale], [4.0, 7, 8]),
        (BreathingStyle.even, [BreathPhase.inhale, .exhale], [5.0, 5])
    ])
    func stepsPerStyle(_ style: BreathingStyle, _ phases: [BreathPhase], _ seconds: [TimeInterval]) {
        let steps = BreathingPattern.steps(style)
        #expect(steps.map(\.0) == phases)
        #expect(steps.map(\.1) == seconds)
    }

    @Test(arguments: [(BreathingStyle.box, 16.0), (.relax, 19), (.even, 10)])
    func cycleLength(_ style: BreathingStyle, _ length: TimeInterval) {
        #expect(BreathingPattern.cycleLength(style) == length)
    }

    @Test(arguments: [
        (BreathingStyle.box, 0.0, BreathPhase.inhale, 4.0, 0),
        (.box, 2, .inhale, 2, 0),
        (.box, 4, .hold, 4, 0),
        (.box, 6.5, .hold, 1.5, 0),
        (.box, 8, .exhale, 4, 0),
        (.box, 12, .rest, 4, 0),
        (.box, 15, .rest, 1, 0),
        (.box, 16, .inhale, 4, 1),
        (.box, 21, .hold, 3, 1),
        (.relax, 0, .inhale, 4, 0),
        (.relax, 4, .hold, 7, 0),
        (.relax, 10, .hold, 1, 0),
        (.relax, 11, .exhale, 8, 0),
        (.relax, 18, .exhale, 1, 0),
        (.relax, 19, .inhale, 4, 1),
        (.relax, 30, .exhale, 8, 1),
        (.even, 0, .inhale, 5, 0),
        (.even, 5, .exhale, 5, 0),
        (.even, 7.5, .exhale, 2.5, 0),
        (.even, 10, .inhale, 5, 1),
        (.even, 23, .inhale, 2, 2)
    ])
    func stepAt(_ style: BreathingStyle, _ elapsed: TimeInterval, _ phase: BreathPhase, _ remaining: TimeInterval, _ cycle: Int) {
        let step = BreathingPattern.step(style, at: elapsed)
        #expect(step.phase == phase)
        #expect(abs(step.remaining - remaining) < 0.0001)
        #expect(step.cycle == cycle)
    }

    @Test(arguments: [(BreathingStyle.box, 4.0), (.relax, 4), (.even, 5)])
    func negativeElapsedActsAsZero(_ style: BreathingStyle, _ firstInhale: TimeInterval) {
        let step = BreathingPattern.step(style, at: -3)
        #expect(step == BreathingPattern.step(style, at: 0))
        #expect(step.phase == .inhale)
        #expect(step.remaining == firstInhale)
        #expect(step.cycle == 0)
    }

    @Test func phaseRawValuesAreStable() {
        #expect([BreathPhase.inhale, .hold, .exhale, .rest].map(\.rawValue) == ["inhale", "hold", "exhale", "rest"])
    }
}
