import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker calendar events")
struct EngineTrackerEventTests {
    private let standup = meeting(from: wed(10, 30), to: wed(11))

    private func atStandup(_ mode: EventMode = .logAndTell, quiet: Bool = false) -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([standup], mode: mode)
        h.start("Spec", minutes: quiet ? 60 : 30, quiet: quiet)
        h.advance(minutes: 30)
        return h
    }

    @Test func logAndTellSwitchesAtTheEventStartAndShowsTheNoteForOneMinute() {
        let h = atStandup()
        #expect(h.saved.map(\.text) == ["Spec"])
        #expect(h.saved.first?.end == wed(10, 30))
        #expect(h.running?.kind == .event)
        #expect(h.running?.text == "Standup")
        #expect(h.running?.start == wed(10, 30))
        #expect(h.running?.sourceEventID == "m1")
        #expect(h.notes == [.event(standup)])
        #expect(h.engine.trackerNoteState()?.endedText == "Spec")
        #expect(h.engine.trackerNoteState()?.calendarTitle == "Gmail Work")
        #expect(h.engine.nextTickDelay() <= 60)
        h.advance(minutes: 1)
        #expect(h.noteCloses == 1)
        #expect(h.engine.trackerNoteState() == nil)
    }

    @Test func noStillOnItAsksBeforeTheEventEndAndTheEndOpensWhatNowWithTheStartedRow() {
        let h = atStandup()
        h.advance(minutes: 29)
        #expect(h.promptKind == nil)
        #expect(!h.trackerShows.contains(.stillOnIt))
        h.advance(minutes: 1)
        #expect(h.promptKind == .whatNow)
        #expect(h.engine.trackerPromptState(.whatNow)?.switchTimes == [wed(11)])
        h.clock.advance(minutes: 10)
        h.engine.startActivity(h.work("Review"), switchAt: wed(11, 5))
        #expect(h.saved.last?.text == "Standup")
        #expect(h.saved.last?.end == wed(11, 5))
        #expect(h.saved.last?.kind == .event)
    }

    @Test func theEventWinsOverAStillOnItAtTheSameMoment() {
        let h = atStandup()
        #expect(!h.trackerShows.contains(.stillOnIt))
        #expect(h.promptKind == nil)
    }

    @Test func undoRemovesTheEventActivityAndContinuesTheOldOne() {
        let h = atStandup()
        let oldID = h.saved[0].id
        h.engine.undoEventNote()
        #expect(h.running?.id == oldID)
        #expect(h.running?.text == "Spec")
        #expect(h.running?.start == wed(10))
        #expect(h.saved.isEmpty)
        #expect(h.noteCloses == 1)
        h.advance(minutes: 1)
        #expect(h.running?.text == "Spec")
        #expect(h.notes.count == 1)
    }

    @Test func notAttendingRemovesTheEventAndOpensWhatNowFromTheEventStart() {
        let h = atStandup()
        h.clock.advance(minutes: 10)
        h.engine.notAttendingEvent("m1")
        #expect(h.running == nil)
        #expect(h.eventItems.isEmpty)
        #expect(h.promptKind == .whatNow)
        #expect(h.engine.trackerPromptState(.whatNow)?.switchTimes.first == wed(10, 30))
    }

    @Test func aCategoryPickInTheNoteChangesTheActivityAndIsKeptForThatTitle() {
        let h = atStandup()
        h.engine.setEventCategory("Meeting")
        #expect(h.running?.category == "Meeting")
        #expect(h.engine.data.prefs.tracker.eventCategoryByTitle["Standup"] == "Meeting")
        #expect(h.engine.trackerNoteState()?.category == "Meeting")
    }

    @Test func quietTimeHidesTheNoteButTheEventIsStillLogged() {
        let h = atStandup(quiet: true)
        #expect(h.running?.text == "Standup")
        #expect(h.notes.isEmpty)
    }

    @Test func askFirstShowsThePromptAndTheOldActivityGoesOn() {
        let h = atStandup(.askFirst)
        #expect(h.promptKind == .eventAsk)
        #expect(h.trackerShows.last == .eventAsk)
        #expect(h.running?.text == "Spec")
        #expect(h.notes.isEmpty)
        h.advance(minutes: 20)
        #expect(h.promptKind == .eventAsk)
    }

    @Test func askFirstYesLogsFromTheEventStartAlsoWhenLate() {
        let h = atStandup(.askFirst)
        h.advance(minutes: 12)
        h.engine.answerEventAsk(true)
        #expect(h.promptKind == nil)
        #expect(h.saved.first?.end == wed(10, 30))
        #expect(h.running?.text == "Standup")
        #expect(h.running?.start == wed(10, 30))
    }

    @Test func askFirstNoKeepsTheOldActivityAndNeverAsksAgain() {
        let h = atStandup(.askFirst)
        h.engine.answerEventAsk(false)
        #expect(h.promptKind == nil)
        #expect(h.running?.text == "Spec")
        h.advance(minutes: 1)
        #expect(h.trackerShows.count { $0 == .eventAsk } == 1)
        h.engine.openTrackerPanel()
        #expect(h.engine.trackerPromptState(.center)?.runningEvent == nil)
    }

    @Test func askFirstCategoryPickIsUsedByYes() {
        let h = atStandup(.askFirst)
        h.engine.setEventCategory("Meeting")
        h.engine.answerEventAsk(true)
        #expect(h.running?.category == "Meeting")
    }
}
