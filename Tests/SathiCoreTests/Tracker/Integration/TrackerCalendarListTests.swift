import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Tracker calendar list")
struct TrackerCalendarListTests {
    private let work = CalendarChoice(id: "work", title: "Office Work", account: "Google", colorHex: 0x4CC3F5)

    @Test func anEmptyListAtLaunchIsReadAgainWhenThePanelOpens() {
        let h = EngineHarness.tracker(at: wed(10))
        h.calendarWriter.choices = []
        h.engine.refreshCalendarAccess()
        #expect(h.engine.calendarChoices().isEmpty)
        h.calendarWriter.choices = [work]
        h.engine.openTrackerPanel()
        #expect(h.engine.trackerPromptState(.center)?.calendars == [work])
    }

    @Test func anEmptyListIsNotKept() {
        let h = EngineHarness.tracker(at: wed(10))
        h.calendarWriter.choices = []
        h.engine.refreshCalendarAccess()
        h.calendarWriter.choices = [work]
        #expect(h.engine.calendarChoices() == [work])
    }

    @Test func aNewCalendarShowsInTheNextPrompt() {
        let h = EngineHarness.tracker(at: wed(10))
        _ = h.engine.calendarChoices()
        let added = CalendarChoice(id: "learn", title: "Learning", account: "Google", colorHex: 0x5FD39A)
        h.calendarWriter.choices.append(added)
        h.engine.openTrackerPanel()
        #expect(h.engine.trackerPromptState(.center)?.calendars.contains(added) == true)
    }
}
