import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker ask every edges")
struct EngineTrackerAskEveryEdgeTests {
    @Test func aQuietActivityIsAskedAndConfirmedAtItsLengthEnd() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Deep work", minutes: 30, quiet: true)
        #expect(h.running?.askAt == wed(10, 30))
        #expect(h.running?.confirmedUntil == wed(10, 30))
        h.clock.advance(minutes: 25)
        h.engine.presenceChanged(.locked)
        #expect(h.saved.first?.end == wed(10, 25))
    }

    @Test func aChangeDuringQuietTimeKeepsTheAskTime() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Deep work", minutes: 30, quiet: true)
        h.advance(minutes: 5)
        h.engine.setTrackerAskEvery(10)
        #expect(h.running?.askAt == wed(10, 30))
    }

    @Test func aLongerAskEveryAfterASkipNeverAsksSooner() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: nil)
        h.advance(minutes: 15)
        h.engine.skipTrackerPrompt()
        h.advance(minutes: 5)
        h.engine.setTrackerAskEvery(20)
        #expect(h.running?.askAt == wed(10, 35))
        h.engine.tick()
        #expect(h.promptKind == nil)
    }

    @Test func aPickedTimeMovesByTheDifference() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: nil)
        h.advance(minutes: 15)
        h.engine.stillOnIt(minutes: 30)
        h.advance(minutes: 5)
        h.engine.setTrackerAskEvery(20)
        #expect(h.running?.askAt == wed(10, 50))
        #expect(h.running?.confirmedUntil == wed(10, 45))
    }
}
