import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker calendar write")
struct EngineTrackerCalendarWriteTests {
    private func startWithCalendar(_ h: EngineHarness, _ text: String = "Spec") {
        var d = h.work(text)
        d.calendarID = "work"
        h.engine.startActivity(d)
    }

    private func stored(_ h: EngineHarness, eventID: String? = "ev9") -> Activity {
        let a = Activity(text: "Spec", category: "Coding", start: wed(9), end: wed(9, 30), calendarID: "work", eventID: eventID)
        h.activities.save(ActivityMonth(key: MonthKey(wed(9), calendar: .current), items: [a]))
        return a
    }

    @Test func addToCalendarIsOffByDefaultAndTheMenuListsWritableCalendarsByAccount() {
        #expect(TrackerPrefs().calendarOnByDefault == false)
        let h = EngineHarness.tracker(at: wed(10))
        let s = h.engine.trackerPromptState(.whatNow)
        #expect(s?.draft.calendarID == nil)
        #expect(s?.calendars.map(\.account) == ["Gmail", "iCloud"])
    }

    @Test func anActivityWithACalendarSavesOneEventWithItsRealStartAndEndAndKeepsTheID() {
        let h = EngineHarness.tracker(at: wed(10))
        startWithCalendar(h)
        h.clock.advance(minutes: 42)
        h.start("Next")
        #expect(h.calendarWriter.saved == [CalendarEventDraft(calendarID: "work", title: "Spec", start: wed(10), end: wed(10, 42))])
        #expect(h.saved.first?.eventID == "e1")
        #expect(h.saved.first?.calendarID == "work")
    }

    @Test func anActivityWithoutACalendarWritesNoEvent() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Spec")
        h.clock.advance(minutes: 20)
        h.start("Next")
        #expect(h.calendarWriter.saved.isEmpty)
        #expect(h.saved.first?.eventID == nil)
    }

    @Test(arguments: [CalendarSaveResult.failed, .calendarMissing])
    func aCalendarFailureKeepsTheActivityWithoutAnEventAndNeverBlocks(_ result: CalendarSaveResult) {
        let h = EngineHarness.tracker(at: wed(10))
        h.calendarWriter.nextSaveResult = result
        startWithCalendar(h)
        h.clock.advance(minutes: 20)
        h.start("Next")
        #expect(h.saved.count == 1)
        #expect(h.saved.first?.calendarID == "work")
        #expect(h.saved.first?.eventID == nil)
        #expect(h.running?.text == "Next")
    }

    @Test func aReportEditUpdatesTheEvent() {
        let h = EngineHarness.tracker(at: wed(12))
        let a = stored(h)
        let edit = ActivityEdit(text: "Spec v2", category: "Review", start: wed(9, 5), end: wed(9, 40))
        h.engine.editActivity(a.id, edit)
        #expect(h.calendarWriter.updated.map(\.0) == ["ev9"])
        #expect(h.calendarWriter.updated.first?.1 == CalendarEventDraft(calendarID: "work", title: "Spec v2", start: wed(9, 5), end: wed(9, 40)))
        #expect(h.saved.first?.eventID == "ev9")
    }

    @Test(arguments: [CalendarSaveResult.calendarMissing, .failed])
    func aMissingEventChangesOnlyTheLog(_ result: CalendarSaveResult) {
        let h = EngineHarness.tracker(at: wed(12))
        let a = stored(h)
        h.calendarWriter.nextUpdateResult = result
        h.engine.editActivity(a.id, ActivityEdit(text: "Spec v2", category: "Coding", start: wed(9), end: wed(9, 40)))
        #expect(h.saved.first?.text == "Spec v2")
        #expect(h.saved.first?.eventID == "ev9")
        #expect(h.calendarWriter.saved.isEmpty)
    }

    @Test func anEditOfAnActivityWithoutAnEventWritesNothing() {
        let h = EngineHarness.tracker(at: wed(12))
        let a = stored(h, eventID: nil)
        h.engine.editActivity(a.id, ActivityEdit(text: "Spec v2", category: "Coding", start: wed(9), end: wed(9, 40)))
        #expect(h.calendarWriter.updated.isEmpty)
        #expect(h.calendarWriter.saved.isEmpty)
    }

    @Test func aDeleteDeletesTheEvent() {
        let h = EngineHarness.tracker(at: wed(12))
        let a = stored(h)
        h.engine.deleteActivity(a.id)
        #expect(h.calendarWriter.deleted == ["ev9"])
        #expect(h.saved.isEmpty)
    }

    @Test func anActivityFromAnEventNeverWritesAnEvent() {
        let h = EngineHarness.tracker(at: wed(10))
        var d = h.work("Standup")
        d.calendarID = "work"
        d.sourceEventID = "m1"
        h.engine.startActivity(d)
        h.clock.advance(minutes: 20)
        h.start("Next")
        #expect(h.calendarWriter.saved.isEmpty)
        #expect(h.saved.first?.sourceEventID == "m1")
    }
}
