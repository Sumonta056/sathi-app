import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine activity prompt Started")
struct EnginePromptStartedTests {
    private func screen(_ h: EngineHarness, _ kind: PromptKind) -> ActivityPromptScreen? {
        h.engine.trackerPromptState(kind).map(ActivityPromptBuilder.screen)
    }

    private func clock(_ date: Date) -> String { Copywriter.trackerClock(date, calendar: .current) }

    private func endsAfterOneAnswer() -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.askEveryMinutes = 15 }
        h.start("Spec", minutes: 30)
        h.advance(minutes: 30)
        h.engine.stillOnIt(minutes: 15)
        h.advance(minutes: 15)
        #expect(h.promptKind == .stillOnIt)
        h.clock.advance(minutes: 7)
        return h
    }

    @Test func endsOffersStartedTimesFromTheLastAnswer() {
        let h = endsAfterOneAnswer()
        let want = [wed(10, 30), wed(10, 35), wed(10, 40), wed(10, 45), wed(10, 50), wed(10, 52)]
        #expect(screen(h, .stillOnIt)?.startedChoices == want)
    }

    @Test func startWithAPickedTimeInEndsSwitchesAtThatSecond() {
        let h = endsAfterOneAnswer()
        h.start("Next", at: wed(10, 40))
        #expect(h.saved.map(\.text) == ["Spec"])
        #expect(h.saved.first?.end == wed(10, 40))
        #expect(h.running?.text == "Next")
        #expect(h.running?.start == wed(10, 40))
        #expect(h.promptKind == nil)
    }

    private func backAfterLock() -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.askEveryMinutes = 30 }
        h.start("Write spec", minutes: 30)
        h.clock.advance(minutes: 20)
        h.engine.presenceChanged(.locked)
        h.clock.advance(minutes: 30)
        h.engine.presenceChanged(.unlocked)
        #expect(h.promptKind == .welcomeBack)
        return h
    }

    @Test func backOffersStartedTimesFromTheAwayEnd() {
        let h = backAfterLock()
        h.clock.advance(minutes: 12)
        #expect(screen(h, .welcomeBack)?.startedChoices == [wed(10, 50), wed(10, 55), wed(11), wed(11, 2)])
    }

    @Test func backNamesTheActivityTheAwayStopped() {
        let h = backAfterLock()
        #expect(screen(h, .welcomeBack)?.message == "Write spec stopped at " + clock(wed(10, 20)) + " when the Mac was locked.")
    }

    @Test func shortcutWhileRunningOffersStartedTimesFromTheLastAnswer() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Spec", minutes: 30)
        h.clock.advance(minutes: 12)
        h.engine.openTrackerPanel()
        #expect(screen(h, .center)?.startedChoices == [wed(10), wed(10, 5), wed(10, 10), wed(10, 12)])
    }

    @Test func shortcutWithNothingRunningHidesTheStartedLink() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.skipTrackerPrompt()
        h.clock.advance(minutes: 12)
        h.engine.openTrackerPanel()
        #expect(screen(h, .center)?.startedChoices == [])
    }

    @Test func askAfterDoneNamesTheDoneActivityAndOffersTimesFromTheLastAnswer() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Spec", minutes: 30)
        h.advance(minutes: 30)
        h.engine.doneActivity()
        h.clock.advance(minutes: 2)
        let s = screen(h, .whatNow)
        #expect(s?.message == "Nothing is running. Spec ended at " + clock(wed(10, 30)) + ".")
        #expect(s?.startedChoices.first == wed(10))
        #expect(s?.startedChoices.last == wed(10, 32))
    }

    @Test func askNamesTheLastActivityOfToday() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Spec", minutes: 30)
        h.advance(minutes: 30)
        h.engine.doneActivity()
        h.engine.skipTrackerPrompt()
        h.advance(minutes: 30)
        #expect(h.promptKind == .whatNow)
        #expect(screen(h, .whatNow)?.message == "Nothing is running. Spec ended at " + clock(wed(10, 30)) + ".")
    }

    @Test func eventHasAFixedStartAndNamesItsCalendar() {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([meeting(from: wed(10, 30), to: wed(11))], mode: .askFirst)
        h.start("Spec", minutes: 30)
        h.advance(minutes: 30)
        #expect(h.promptKind == .eventAsk)
        let s = screen(h, .eventAsk)
        #expect(s?.fixedStart == wed(10, 30))
        #expect(s?.startedChoices == [])
        #expect(s?.calendarNote == "Already in your Gmail Work calendar, so Sathi adds no copy.")
    }
}
