import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine calendar page edit keeps the user's event")
struct EngineCalendarPageEditKeepsTests {
    private func event(
        title: String = "Plan", start: Date = day(2026, 3, 4, 15), end: Date = day(2026, 3, 4, 16)
    ) -> CalendarEventInfo {
        CalendarEventInfo(id: "e1", title: title, start: start, end: end, calendarID: "work")
    }

    private func moved(_ e: CalendarEventInfo, _ h: EngineHarness) -> CalendarPageWriteResult {
        h.showPage([e])
        var f = h.engine.calendarPageForm(for: e)
        f.start = f.start.addingTimeInterval(30 * 60)
        f.end = f.end.addingTimeInterval(30 * 60)
        return h.engine.saveCalendarPageEvent(f)
    }

    @Test func pageEditUsesTheTimesOnlyUpdate() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        #expect(moved(event(), h) == .saved("e1"))
        #expect(h.calendarWriter.updated.isEmpty)
        #expect(h.calendarWriter.timesUpdated.map(\.0) == ["e1"])
        let draft = CalendarEventDraft(
            calendarID: "work", title: "Plan", start: day(2026, 3, 4, 15, 30), end: day(2026, 3, 4, 16, 30)
        )
        #expect(h.calendarWriter.timesUpdated.first?.1 == draft)
    }

    @Test func aLongTitleTheUserDidNotTouchIsSentUnchanged() {
        let long = "Quarterly planning with finance, product and design leads — room 4B\nsecond floor"
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        #expect(moved(event(title: long), h) == .saved("e1"))
        #expect(h.calendarWriter.timesUpdated.first?.1.title == long)
    }

    @Test func aChangedTitleIsCleanedAndCut() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        h.showPage([event()])
        var f = h.engine.calendarPageForm(for: event())
        f.title = "  " + String(repeating: "a", count: 70) + "\n"
        #expect(h.engine.saveCalendarPageEvent(f) == .saved("e1"))
        #expect(h.calendarWriter.timesUpdated.first?.1.title == String(repeating: "a", count: 60))
    }

    @Test func aTimedEventLongerThanADayIsReadOnly() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        let e = event(start: day(2026, 3, 4, 9), end: day(2026, 3, 6, 17))
        #expect(h.engine.calendarPageForm(for: e).readOnly)
    }

    @Test func aTimedEventOfExactlyOneDayCanBeEdited() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        let e = event(start: day(2026, 3, 4, 9), end: day(2026, 3, 5, 9))
        #expect(!h.engine.calendarPageForm(for: e).readOnly)
    }

    @Test func aMultiDayEventEditIsRefusedWithNoWriterCall() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        let e = event(start: day(2026, 3, 4, 9), end: day(2026, 3, 6, 17))
        h.showPage([e])
        var f = h.engine.calendarPageForm(for: e)
        f.readOnly = false
        f.start = day(2026, 3, 4, 9, 30)
        f.end = day(2026, 3, 4, 17)
        #expect(h.engine.saveCalendarPageEvent(f) == .refused)
        #expect(h.writerCalls == 0)
    }
}
