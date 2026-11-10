import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker next popup")
struct EngineTrackerNextPopupTests {
    @Test func aRunningActivityIsAskedAtItsAskTime() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 30, offset: 5)
        #expect(h.engine.trackerNextPopup == wed(10, 35))
    }

    @Test func anOpenPromptHasNoNextPopup() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 15)
        h.advance(minutes: 15)
        #expect(h.promptKind == .stillOnIt)
        #expect(h.engine.trackerNextPopup == nil)
    }

    @Test func aSkippedWhatNowAsksAgainAfterAskEvery() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 15)
        h.advance(minutes: 15)
        h.engine.doneActivity()
        h.engine.skipTrackerPrompt()
        #expect(h.engine.runningActivity == nil)
        #expect(h.engine.trackerNextPopup == wed(10, 30))
    }

    @Test func quietTimeMovesTheNextPopupToItsEnd() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 30, quiet: true)
        h.engine.data.live.tracker.running?.askAt = wed(10, 20)
        #expect(h.engine.trackerNextPopup == wed(10, 30))
    }

    @Test func theNextPopupTextNamesTheTime() {
        #expect(Copywriter.trackerNextAsk(wed(15, 53), calendar: .current) == "Next ask " + Copywriter.trackerClock(wed(15, 53), calendar: .current))
        #expect(Copywriter.trackerSinceFor(wed(15, 1), now: wed(15, 53), calendar: .current).hasSuffix(" · 52 min"))
    }
}
