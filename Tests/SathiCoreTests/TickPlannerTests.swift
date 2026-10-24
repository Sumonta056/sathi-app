import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("TickPlanner")
struct TickPlannerTests {
    private let now = day(2026, 3, 4, 10)

    @Test func sessionTicksEverySecond() {
        #expect(TickPlanner.delay(now: now, phase: .session, deadlines: [], focusRemaining: nil) == Timing.activeTick)
    }

    @Test func idleWithNothingWaitsTheMaximum() {
        #expect(TickPlanner.delay(now: now, phase: .idle, deadlines: [], focusRemaining: nil) == Timing.idleTickMax)
    }

    @Test func wakesAtTheSoonestFutureDeadline() {
        let deadlines = [now.addingTimeInterval(40), now.addingTimeInterval(12), now.addingTimeInterval(-5)]
        #expect(TickPlanner.delay(now: now, phase: .idle, deadlines: deadlines, focusRemaining: nil) == 12)
    }

    @Test func pastDeadlinesNeverCauseABusyLoop() {
        let deadlines = [now.addingTimeInterval(-100)]
        #expect(TickPlanner.delay(now: now, phase: .idle, deadlines: deadlines, focusRemaining: nil) == Timing.idleTickMax)
    }

    @Test func wakesWhenTheMinuteLabelChanges() {
        let delay = TickPlanner.delay(now: now, phase: .idle, deadlines: [], focusRemaining: 3625)
        #expect(abs(delay - (25 + Timing.minuteEdgePadding)) < 0.0001)
    }

    @Test func neverShorterThanTheMinimum() {
        let delay = TickPlanner.delay(now: now, phase: .idle, deadlines: [now.addingTimeInterval(0.01)], focusRemaining: nil)
        #expect(delay == Timing.minTick)
    }

    @Test func toleranceIsCapped() {
        #expect(TickPlanner.tolerance(for: 1) == 0.1)
        #expect(TickPlanner.tolerance(for: 60) == Timing.maxTickTolerance)
    }
}
