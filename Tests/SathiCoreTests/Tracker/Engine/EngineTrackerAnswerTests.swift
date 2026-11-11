import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker answers")
struct EngineTrackerAnswerTests {
    @Test func anAnswerFiveMinutesLateShowsTheWaitedMinutes() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 15)
        h.advance(minutes: 15)
        h.advance(minutes: 4)
        #expect(h.engine.trackerPromptState(.stillOnIt)?.isLate == false)
        h.advance(minutes: 2)
        #expect(h.engine.trackerPromptState(.stillOnIt)?.waitedMinutes == 6)
    }

    @Test func lateStillOnItContinuesToNowAndConfirmsOnlyToNow() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 15)
        h.advance(minutes: 25)
        h.engine.stillOnItLate()
        #expect(h.running?.confirmedUntil == wed(10, 25))
        #expect(h.running?.lastAnswer == wed(10, 25))
        #expect(h.running?.askAt == wed(10, 40))
    }

    @Test func doneOpensWhatNowAtOnceWithTheStartedRow() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 15)
        h.advance(minutes: 15)
        h.engine.stillOnIt(minutes: 5)
        h.advance(minutes: 12)
        h.engine.doneActivity()
        let s = h.engine.trackerPromptState(.whatNow)
        #expect(h.promptKind == .whatNow)
        #expect(s?.switchTimes == [wed(10, 15), wed(10, 20), wed(10, 25), wed(10, 27)])
        #expect(s?.switchTimes.last == h.clock.now)
        #expect(h.running != nil)
    }

    @Test func aLongActivityOffersMoreThanFourSwitchTimes() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 15)
        h.advance(minutes: 40)
        h.engine.doneActivity()
        let chips = h.engine.trackerPromptState(.whatNow)?.switchTimes ?? []
        #expect(chips.count > 4)
    }

    @Test func thePickedSwitchTimeEndsTheOldAndStartsTheNewAtTheSameSecond() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Old", minutes: 15)
        h.advance(minutes: 27)
        h.engine.doneActivity()
        h.engine.startActivity(h.work("New"), switchAt: wed(10, 20))
        #expect(h.saved.map(\.text) == ["Old"])
        #expect(h.saved.first?.end == wed(10, 20))
        #expect(h.running?.text == "New")
        #expect(h.running?.start == wed(10, 20))
    }

    @Test func skipAfterDoneEndsTheOldActivityAtThePickedTime() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Old", minutes: 15)
        h.advance(minutes: 27)
        h.engine.doneActivity()
        h.engine.skipTrackerPrompt(switchAt: wed(10, 15))
        #expect(h.running == nil)
        #expect(h.saved.first?.end == wed(10, 15))
    }
}
