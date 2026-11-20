import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker prompt calendar starts on None")
struct EngineTrackerPromptCalendarStartTests {
    private let three = [
        CalendarChoice(id: "work", title: "Work", account: "Gmail", colorHex: 0x4285F4),
        CalendarChoice(id: "home", title: "Home", account: "iCloud", colorHex: 0x34A853),
        CalendarChoice(id: "team", title: "Team", account: "iCloud", colorHex: 0xC9B8FF)
    ]

    @Test func aPromptStartsOnNoneWithATrackerDefaultCalendar() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.defaultCalendarID = "home" }
        h.engine.openTrackerPanel()
        #expect(h.engine.trackerPromptState(.center)?.draft.calendarID == nil)
        #expect(h.engine.trackerPromptState(.center)?.defaultCalendarID == "home")
    }

    @Test func aPromptStartsOnNoneWithASystemDefaultCalendar() {
        let h = EngineHarness.tracker(at: wed(10))
        h.calendarWriter.defaultID = "home"
        h.engine.openTrackerPanel()
        #expect(h.engine.trackerPromptState(.center)?.draft.calendarID == nil)
    }

    @Test func anOldSavedCalendarOnByDefaultStillStartsOnNone() throws {
        let json = #"{"isOn":true,"calendarOnByDefault":true,"defaultCalendarID":"home"}"#
        let old = try JSONDecoder().decode(TrackerPrefs.self, from: Data(json.utf8))
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker = old }
        h.engine.openTrackerPanel()
        #expect(h.engine.trackerPromptState(.center)?.draft.calendarID == nil)
        #expect(h.engine.trackerPromptState(.whatNow)?.draft.calendarID == nil)
    }

    @Test func anAutomaticAskStartsOnNone() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.defaultCalendarID = "work" }
        #expect(h.engine.trackerPromptState(.whatNow)?.draft.calendarID == nil)
    }

    @Test func theDefaultCalendarComesFirstAndTheOthersKeepTheirOrder() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.defaultCalendarID = "team" }
        h.calendarWriter.choices = three
        h.engine.openTrackerPanel()
        #expect(h.engine.trackerPromptState(.center)?.calendars.map(\.id) == ["team", "work", "home"])
    }

    @Test func theSecondCalendarAsDefaultMovesToTheFront() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.defaultCalendarID = "home" }
        h.engine.openTrackerPanel()
        #expect(h.engine.trackerPromptState(.center)?.calendars.map(\.id) == ["home", "work"])
    }

    @Test func noTrackerDefaultKeepsTheCalendarOrder() {
        let h = EngineHarness.tracker(at: wed(10))
        h.calendarWriter.choices = three
        h.engine.openTrackerPanel()
        #expect(h.engine.trackerPromptState(.center)?.calendars.map(\.id) == ["work", "home", "team"])
    }

    @Test func aGoneDefaultKeepsTheCalendarOrder() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.defaultCalendarID = "gone" }
        h.calendarWriter.choices = three
        h.engine.openTrackerPanel()
        #expect(h.engine.trackerPromptState(.center)?.calendars.map(\.id) == ["work", "home", "team"])
    }
}
