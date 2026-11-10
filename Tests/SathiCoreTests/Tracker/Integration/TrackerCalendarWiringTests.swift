import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Tracker calendar wiring")
struct TrackerCalendarWiringTests {
    private let standup = meeting(from: wed(10, 30), to: wed(11))

    private func atStandup(_ mode: EventMode) -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([standup], mode: mode)
        h.start("Spec", minutes: 30, quiet: false)
        h.advance(minutes: 30)
        return h
    }

    @Test func theAskFirstPromptStateCarriesTheEventTitleAndID() {
        let h = atStandup(.askFirst)
        let s = h.engine.trackerPromptState(.eventAsk)
        #expect(s?.event?.id == "m1")
        #expect(s?.draft.text == "Standup")
        #expect(s?.draft.sourceEventID == "m1")
    }

    @Test func turningTheTrackerOffClosesTheEventNote() {
        let h = atStandup(.logAndTell)
        #expect(h.engine.trackerNoteState() != nil)
        h.engine.data.prefs.tracker.isOn = false
        #expect(h.noteCloses == 1)
        #expect(h.engine.trackerNoteState() == nil)
    }
}
