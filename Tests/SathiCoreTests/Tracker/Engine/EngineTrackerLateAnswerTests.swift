import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker late answers")
struct EngineTrackerLateAnswerTests {
    private func askedAtTen15() -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 15)
        h.advance(minutes: 15)
        return h
    }

    @Test func anOpenStillOnItWakesTheEngineAtTheLateTime() {
        let h = askedAtTen15()
        #expect(h.promptKind == .stillOnIt)
        #expect(h.engine.nextTickDelay() <= Timing.lateAnswer)
    }

    @Test func atTheLateTimeTheOpenStillOnItIsShownAgainInItsLateForm() {
        let h = askedAtTen15()
        #expect(h.stillOnItShows == 1)
        h.advance(minutes: 5)
        #expect(h.stillOnItShows == 2)
        #expect(h.engine.trackerPromptState(.stillOnIt)?.waitedMinutes == 5)
        h.advance(minutes: 5)
        #expect(h.stillOnItShows == 2)
    }

    @Test func theLateRefreshPlaysNoSecondTap() {
        let h = askedAtTen15()
        let taps = h.tinks
        h.advance(minutes: 5)
        #expect(h.tinks == taps)
    }

    @Test func noLateRefreshWhenTheAnswerComesInTime() {
        let h = askedAtTen15()
        h.advance(minutes: 2)
        h.engine.stillOnIt()
        h.advance(minutes: 5)
        #expect(h.stillOnItShows == 1)
    }

    @Test func aLateYesConfirmsOnlyUpToNow() {
        let h = askedAtTen15()
        h.advance(minutes: 10)
        h.engine.stillOnIt(minutes: 30)
        #expect(h.running?.confirmedUntil == wed(10, 25))
        #expect(h.running?.lastAnswer == wed(10, 25))
        #expect(h.running?.askAt == wed(10, 40))
        #expect(h.promptKind == nil)
    }

    @Test func aYesInTimeStillConfirmsUntilTheNextAsk() {
        let h = askedAtTen15()
        h.advance(minutes: 4)
        h.engine.stillOnIt(minutes: 30)
        #expect(h.running?.confirmedUntil == wed(10, 49))
        #expect(h.running?.askAt == wed(10, 49))
    }

    @Test func theDraftUsesTheTrackerDefaultCalendar() {
        let h = EngineHarness.tracker(at: wed(10)) {
            $0.prefs.tracker.calendarOnByDefault = true
            $0.prefs.tracker.defaultCalendarID = "home"
        }
        h.engine.openTrackerPanel()
        #expect(h.engine.trackerPromptState(.center)?.draft.calendarID == "home")
        #expect(h.engine.trackerPromptState(.center)?.defaultCalendarID == "home")
    }

    @Test func withNoTrackerDefaultTheSystemDefaultIsUsed() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.calendarOnByDefault = true }
        h.calendarWriter.defaultID = "home"
        h.engine.openTrackerPanel()
        #expect(h.engine.trackerPromptState(.center)?.draft.calendarID == "home")
    }

    @Test func withNoDefaultAtAllTheFirstWritableCalendarIsUsed() {
        let h = EngineHarness.tracker(at: wed(10)) {
            $0.prefs.tracker.calendarOnByDefault = true
            $0.prefs.tracker.defaultCalendarID = "gone"
        }
        h.engine.openTrackerPanel()
        #expect(h.engine.trackerPromptState(.center)?.draft.calendarID == "work")
    }

    @Test func calendarOffByDefaultStillTellsTheViewTheDefault() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.defaultCalendarID = "home" }
        h.engine.openTrackerPanel()
        let s = h.engine.trackerPromptState(.center)
        #expect(s?.draft.calendarID == nil)
        #expect(s?.defaultCalendarID == "home")
    }
}

private extension EngineHarness {
    var stillOnItShows: Int { trackerShows.count { $0 == .stillOnIt } }
}
