import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine calendar page write guard")
struct EngineCalendarPageWriteGuardTests {
    private func open(_ e: CalendarEventInfo) -> CalendarEventForm {
        CalendarEventForm(eventID: e.id, title: "Changed", start: e.start, end: e.end, calendarID: "work", readOnly: false)
    }

    private func harness(_ events: [CalendarEventInfo]) -> EngineHarness {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        h.calendarWriter.readable = h.calendarWriter.choices + [
            CalendarChoice(id: "holidays", title: "Holidays", account: "iCloud", colorHex: 0)
        ]
        h.showPage(events)
        return h
    }

    static let refused: [CalendarEventInfo] = [
        pageEvent(repeating: true),
        pageEvent(guests: true),
        pageEvent(allDay: true),
        pageEvent(calendar: "holidays")
    ]

    @Test(arguments: refused)
    func saveRefusesAProtectedEvent(_ e: CalendarEventInfo) {
        let h = harness([e])
        #expect(h.engine.saveCalendarPageEvent(open(e)) == .invalid)
        #expect(h.writerCalls == 0)
    }

    @Test(arguments: refused)
    func deleteRefusesAProtectedEvent(_ e: CalendarEventInfo) {
        let h = harness([e])
        #expect(!h.engine.deleteCalendarPageEvent(e.id))
        #expect(h.writerCalls == 0)
    }

    @Test func saveRefusesAnEventThatIsNotFound() {
        let h = harness([])
        #expect(h.engine.saveCalendarPageEvent(open(pageEvent())) == .invalid)
        #expect(h.writerCalls == 0)
    }

    @Test func deleteRefusesAnEventThatIsNotFound() {
        let h = harness([])
        #expect(!h.engine.deleteCalendarPageEvent("e1"))
        #expect(h.writerCalls == 0)
    }

    @Test func deleteRefusesAnEventThatBecameASeries() {
        let h = harness([pageEvent()])
        h.calendarWriter.eventsValue = [pageEvent(repeating: true)]
        #expect(!h.engine.deleteCalendarPageEvent("e1"))
        #expect(h.writerCalls == 0)
    }

    @Test func deleteRefusesAnEventThatIsGone() {
        let h = harness([pageEvent()])
        h.calendarWriter.eventsValue = []
        #expect(!h.engine.deleteCalendarPageEvent("e1"))
        #expect(h.writerCalls == 0)
    }

    @Test func saveRefusesAReadOnlyForm() {
        let h = harness([pageEvent()])
        var f = open(pageEvent())
        f.readOnly = true
        #expect(h.engine.saveCalendarPageEvent(f) == .invalid)
        #expect(h.writerCalls == 0)
    }

    @Test func editWithNewTimesFindsTheShownEvent() {
        let h = harness([pageEvent()])
        var f = open(pageEvent())
        f.start = day(2026, 3, 4, 9)
        f.end = day(2026, 3, 4, 10)
        #expect(h.engine.saveCalendarPageEvent(f) == .saved("e1"))
        #expect(h.calendarWriter.updated.first?.1.start == day(2026, 3, 4, 9))
    }

    @Test func editFindsTheEventByAFreshReadWithoutAPageBuild() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        h.calendarWriter.eventsValue = [pageEvent()]
        #expect(h.engine.saveCalendarPageEvent(open(pageEvent())) == .saved("e1"))
    }
}
