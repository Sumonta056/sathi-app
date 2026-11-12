import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker flow")
struct EngineTrackerFlowTests {
    @Test func anOldPrefsFileLoadsWithTheTrackerOffAndNothingAsks() {
        let h = EngineHarness(at: wed(8))
        h.advance(minutes: 600)
        #expect(!h.engine.data.prefs.tracker.isOn)
        #expect(h.presenter.trackerCalls.isEmpty)
        #expect(h.activities.saves == 0)
    }

    @Test func turningTheTrackerOnInsideHoursAsksWhatNow() {
        let h = EngineHarness(at: wed(10))
        h.engine.data.prefs.tracker.isOn = true
        h.engine.tick()
        #expect(h.trackerShows == [.whatNow])
    }

    @Test func atTheStartOfTrackerHoursWhatNowShowsInTheCorner() {
        let h = EngineHarness.tracker(at: wed(8, 50))
        #expect(h.trackerShows.isEmpty)
        h.advance(minutes: 10)
        #expect(h.trackerShows == [.whatNow])
        #expect(PromptKind.whatNow.isCorner)
    }

    @Test func stillOnItShowsAtLengthPlusOffsetWhenThatIsEarlierThanAskEvery() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 10, offset: 3)
        h.advance(minutes: 12)
        #expect(h.promptKind == nil)
        h.advance(minutes: 1)
        #expect(h.promptKind == .stillOnIt)
        #expect(h.trackerShows.last == .stillOnIt)
    }

    @Test func anOpenActivityIsAskedEveryAskEvery() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: nil)
        h.advance(minutes: 15)
        #expect(h.promptKind == .stillOnIt)
        h.engine.stillOnIt()
        h.advance(minutes: 14)
        #expect(h.promptKind == nil)
        h.advance(minutes: 1)
        #expect(h.promptKind == .stillOnIt)
    }

    @Test(arguments: [(Int?.none, 15), (5, 5), (30, 30)])
    func yesSetsTheNextAskToNowPlusThatTime(minutes: Int?, expected: Int) {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 15)
        h.advance(minutes: 15)
        h.engine.stillOnIt(minutes: minutes)
        #expect(h.promptKind == nil)
        #expect(h.running?.askAt == wed(10, 15 + expected))
        #expect(h.running?.lastAnswer == wed(10, 15))
        #expect(h.running?.confirmedUntil == wed(10, 15 + expected))
    }

    @Test func skipInStillOnItChangesNoDataAndAsksAgainAfterAskEvery() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 15)
        h.advance(minutes: 15)
        let before = h.running
        let saves = h.activities.saves
        h.engine.skipTrackerPrompt()
        #expect(h.running?.confirmedUntil == before?.confirmedUntil)
        #expect(h.running?.lastAnswer == before?.lastAnswer)
        #expect(h.activities.saves == saves)
        h.advance(minutes: 14)
        #expect(h.promptKind == nil)
        h.advance(minutes: 1)
        #expect(h.promptKind == .stillOnIt)
    }

    @Test func skipInWhatNowAsksAgainAfterAskEvery() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.skipTrackerPrompt()
        #expect(h.promptKind == nil)
        h.advance(minutes: 14)
        #expect(h.promptKind == nil)
        h.advance(minutes: 1)
        #expect(h.promptKind == .whatNow)
    }

    @Test func noTrackerPromptClosesByItself() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 15)
        h.advance(minutes: 15)
        h.advance(minutes: 180)
        #expect(h.promptKind == .stillOnIt)
        #expect(!h.presenter.trackerCalls.contains(.closePrompt(.stillOnIt)))
    }

    @Test func oneSoftSoundWhenWhatNowOrStillOnItShows() {
        let h = EngineHarness.tracker(at: wed(10))
        #expect(h.tinks == 1)
        h.start(minutes: 15)
        h.advance(minutes: 15)
        #expect(h.tinks == 2)
        h.advance(minutes: 10)
        #expect(h.tinks == 2)
    }

    @Test func noSoundWhenSoundIsOff() {
        let general = EngineHarness.tracker(at: wed(10)) { $0.prefs.general.soundOn = false }
        let tracker = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.playsSound = false }
        #expect(general.trackerShows == [.whatNow])
        #expect(general.tinks == 0)
        #expect(tracker.tinks == 0)
    }

    @Test func aNewActivityEndsTheOldOneAtThatMoment() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("One")
        h.advance(minutes: 10)
        h.start("Two")
        #expect(h.saved.map(\.text) == ["One"])
        #expect(h.saved.first?.end == wed(10, 10))
        #expect(h.running?.text == "Two")
        #expect(h.running?.start == wed(10, 10))
    }

    @Test func anActivityShorterThanSixtySecondsIsNotSaved() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("One")
        h.clock.advance(minutes: 59.0 / 60)
        h.start("Two")
        #expect(h.saved.isEmpty)
        h.clock.advance(minutes: 1)
        h.start("Three")
        #expect(h.saved.map(\.text) == ["Two"])
    }

    @Test func emptyTextIsRefused() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("  \n ")
        #expect(h.running == nil)
        #expect(h.promptKind == .whatNow)
    }
}
