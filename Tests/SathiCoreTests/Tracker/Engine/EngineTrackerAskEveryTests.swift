import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker ask every")
struct EngineTrackerAskEveryTests {
    private func running(minutes: Int? = 30, after waited: Double = 0) -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: minutes)
        if waited > 0 { h.advance(minutes: waited) }
        return h
    }

    @Test func aThirtyMinuteActivityIsAskedAfterAskEveryNotAtItsEnd() {
        let h = running()
        #expect(h.running?.askAt == wed(10, 15))
        h.advance(minutes: 14)
        #expect(h.promptKind == nil)
        h.advance(minutes: 1)
        #expect(h.promptKind == .stillOnIt)
        #expect(h.trackerShows.last == .stillOnIt)
    }

    @Test func anActivityShorterThanAskEveryIsAskedAtItsEnd() {
        let h = running(minutes: 10)
        h.advance(minutes: 9)
        #expect(h.promptKind == nil)
        h.advance(minutes: 1)
        #expect(h.promptKind == .stillOnIt)
    }

    @Test func aShorterAskEveryMovesTheAskTimeToLastAnswerPlusTheNewValue() {
        let h = running(after: 5)
        h.engine.setTrackerAskEvery(10)
        #expect(h.running?.askAt == wed(10, 10))
        h.advance(minutes: 4)
        #expect(h.promptKind == nil)
        h.advance(minutes: 1)
        #expect(h.promptKind == .stillOnIt)
    }

    @Test func anAskTimeInThePastBecomesNowAndThePromptShowsAtOnce() {
        let h = running(after: 12)
        h.engine.setTrackerAskEvery(10)
        #expect(h.running?.askAt == wed(10, 12))
        h.engine.tick()
        #expect(h.promptKind == .stillOnIt)
    }

    @Test func aLongerAskEveryBeforeTheFirstAnswerStopsAtTheLengthEnd() {
        let h = running(after: 5)
        h.engine.setTrackerAskEvery(60)
        #expect(h.running?.askAt == wed(10, 30))
        h.advance(minutes: 24)
        #expect(h.promptKind == nil)
        h.advance(minutes: 1)
        #expect(h.promptKind == .stillOnIt)
    }

    @Test func afterAnAnswerTheNewTimeCountsFromThatAnswerWithNoLengthCap() {
        let h = running(after: 15)
        h.engine.stillOnIt()
        h.advance(minutes: 5)
        h.engine.setTrackerAskEvery(60)
        #expect(h.running?.lastAnswer == wed(10, 15))
        #expect(h.running?.askAt == wed(11, 15))
    }

    @Test func anOpenActivityHasNoLengthCap() {
        let h = running(minutes: nil, after: 5)
        h.engine.setTrackerAskEvery(60)
        #expect(h.running?.askAt == wed(11))
    }

    @Test func confirmedUntilAndLastAnswerDoNotChange() {
        let h = running(after: 5)
        let before = h.running
        h.engine.setTrackerAskEvery(10)
        #expect(h.running?.askAt != before?.askAt)
        #expect(h.running?.confirmedUntil == before?.confirmedUntil)
        #expect(h.running?.lastAnswer == before?.lastAnswer)
    }

    @Test func theSameValueChangesNothing() {
        let h = running(after: 15)
        h.engine.stillOnIt(minutes: 5)
        let before = h.running
        h.engine.setTrackerAskEvery(15)
        #expect(h.running == before)
        #expect(h.running?.askAt == wed(10, 20))
    }

    @Test func aSkippedWhatNowMovesByTheDifference() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.skipTrackerPrompt()
        h.engine.setTrackerAskEvery(10)
        h.advance(minutes: 9)
        #expect(h.promptKind == nil)
        h.advance(minutes: 1)
        #expect(h.promptKind == .whatNow)
    }

    @Test func aSkippedWhatNowMovesLaterWithALongerAskEvery() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.skipTrackerPrompt()
        h.engine.setTrackerAskEvery(30)
        h.advance(minutes: 29)
        #expect(h.promptKind == nil)
        h.advance(minutes: 1)
        #expect(h.promptKind == .whatNow)
    }

    @Test func aSkippedWhatNowNeverMovesIntoThePast() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.skipTrackerPrompt()
        h.advance(minutes: 12)
        #expect(h.promptKind == nil)
        h.engine.setTrackerAskEvery(10)
        h.engine.tick()
        #expect(h.promptKind == .whatNow)
        #expect(h.engine.trackerPrompt?.shownAt == wed(10, 12))
    }

    @Test func aRunningCalendarEventKeepsItsAskTime() throws {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.askEveryMinutes = 30 }
        h.useEvents([meeting(from: wed(10, 30), to: wed(11))])
        h.start("Spec", minutes: 30)
        h.advance(minutes: 35)
        let before = try #require(h.running)
        #expect(before.kind == .event)
        h.engine.setTrackerAskEvery(10)
        #expect(h.running?.askAt == before.askAt)
        h.advance(minutes: 24)
        #expect(!h.trackerShows.contains(.stillOnIt))
    }

    @Test func theNewValueIsSaved() {
        let h = running(after: 5)
        h.engine.setTrackerAskEvery(30)
        #expect(h.store.prefs.tracker.askEveryMinutes == 30)
        #expect(h.engine.data.prefs.tracker.askEveryMinutes == 30)
    }
}
