import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine calendar page events")
struct EngineCalendarPageEventsTests {
    private func design(_ h: EngineHarness, calendarID: String? = "work") -> CalendarEventForm {
        var f = CalendarEventForm.newEvent(at: day(2026, 3, 4, 14, 7), calendarID: calendarID, calendar: h.engine.calendar)
        f.title = "  Design\n"
        return f
    }

    private func info(_ id: String = "e1", calendar: String = "work", repeating: Bool = false, guests: Bool = false) -> CalendarEventInfo {
        var e = CalendarEventInfo(id: id, title: "Plan", start: day(2026, 3, 4, 15), end: day(2026, 3, 4, 16), calendarID: calendar)
        e.isRepeating = repeating
        e.hasGuests = guests
        return e
    }

    @Test func createSavesOneEventAndNoActivity() {
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 10))
        let result = h.engine.saveCalendarPageEvent(design(h))
        let draft = CalendarEventDraft(calendarID: "work", title: "Design", start: day(2026, 3, 4, 14), end: day(2026, 3, 4, 14, 30))
        #expect(result == .saved("e1"))
        #expect(h.calendarWriter.saved == [draft])
        #expect(h.calendarWriter.updated.isEmpty)
        #expect(h.activities.all.isEmpty)
        #expect(h.engine.runningActivity == nil)
        #expect(h.engine.data.prefs.calendarPage.lastCalendarID == "work")
    }

    @Test func saveBumpsTheStoreRevision() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        let before = h.engine.storeRevision
        _ = h.engine.saveCalendarPageEvent(design(h))
        #expect(h.engine.storeRevision > before)
    }

    @Test func editUpdatesTheEvent() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        var f = h.engine.calendarPageForm(for: info())
        f.title = "Plan v2"
        f.calendarID = "home"
        let result = h.engine.saveCalendarPageEvent(f)
        #expect(result == .saved("e1"))
        #expect(h.calendarWriter.saved.isEmpty)
        #expect(h.calendarWriter.updated.map(\.0) == ["e1"])
        let draft = CalendarEventDraft(calendarID: "home", title: "Plan v2", start: day(2026, 3, 4, 15), end: day(2026, 3, 4, 16))
        #expect(h.calendarWriter.updated.first?.1 == draft)
        #expect(h.engine.data.prefs.calendarPage.lastCalendarID == "home")
    }

    @Test func editFormHasTheEventValues() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        let f = h.engine.calendarPageForm(for: info())
        #expect(f == CalendarEventForm(
            eventID: "e1", title: "Plan", start: day(2026, 3, 4, 15), end: day(2026, 3, 4, 16), calendarID: "work", readOnly: false
        ))
    }

    @Test func deleteRemovesTheEvent() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        #expect(h.engine.deleteCalendarPageEvent("e1"))
        #expect(h.calendarWriter.deleted == ["e1"])
    }

    @Test func failedDeleteReturnsFalse() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        h.calendarWriter.nextDeleteResult = false
        #expect(!h.engine.deleteCalendarPageEvent("e1"))
    }

    @Test func failedSaveKeepsTheLastCalendar() {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) { $0.prefs.calendarPage.lastCalendarID = "home" }
        h.calendarWriter.nextSaveResult = .failed
        #expect(h.engine.saveCalendarPageEvent(design(h)) == .failed)
        #expect(h.engine.data.prefs.calendarPage.lastCalendarID == "home")
    }

    @Test func missingCalendarOnUpdateIsAFailure() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        h.calendarWriter.nextUpdateResult = .calendarMissing
        #expect(h.engine.saveCalendarPageEvent(h.engine.calendarPageForm(for: info())) == .failed)
        #expect(h.calendarWriter.saved.isEmpty)
        #expect(h.engine.data.prefs.calendarPage.lastCalendarID == nil)
    }

    @Test func invalidFormWritesNothing() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        var f = design(h)
        f.title = " "
        #expect(h.engine.saveCalendarPageEvent(f) == .invalid)
        #expect(h.calendarWriter.saved.isEmpty)
    }

    @Test func readOnlyFormWritesNothing() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        let f = h.engine.calendarPageForm(for: info(repeating: true))
        #expect(h.engine.saveCalendarPageEvent(f) == .invalid)
        #expect(h.calendarWriter.updated.isEmpty)
    }

    @Test func openInCalendarOpensTheEventLink() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        h.engine.openEventInCalendar("x")
        #expect(h.links.opened.last == URL(string: "ical://ekevent/x"))
    }

    @Test func writeMarksTrackerEventsStale() {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([], mode: .logAndTell)
        h.start("Spec", minutes: 300, quiet: true)
        var f = CalendarEventForm.newEvent(at: wed(14), calendarID: "work", calendar: h.engine.calendar)
        f.title = "Review"
        guard case let .saved(id) = h.engine.saveCalendarPageEvent(f) else {
            Issue.record("save failed")
            return
        }
        h.calendarWriter.eventsValue = [meeting(id, "Review", from: wed(14), to: wed(14, 30))]
        #expect(h.activities.all.isEmpty)
        h.clock.now = wed(14)
        h.engine.tick()
        #expect(h.running?.sourceEventID == id)
        #expect(h.running?.text == "Review")
    }
}
