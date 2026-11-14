import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine calendar page close")
struct EngineCalendarPageCloseTests {
    private func openedPage() -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(10), activities: [Activity(text: "Old", start: day(2026, 1, 5, 9), end: day(2026, 1, 5, 10))])
        h.calendarWriter.eventsValue = [pageEvent()]
        h.engine.calendarPageOpened()
        _ = h.engine.calendarPage(.containing(day(2026, 1, 5, 12), kind: .month, calendar: h.engine.calendar))
        return h
    }

    @Test func closeDropsTheCachedEventRead() {
        let h = openedPage()
        #expect(h.engine.calendarPageRead != nil)
        h.engine.calendarPageClosed()
        #expect(h.engine.calendarPageRead == nil)
        #expect(h.engine.calendarPageEventsByID.isEmpty)
    }

    @Test func closeReleasesTheBrowsedActivityMonths() {
        let h = openedPage()
        let before = h.activities.releases
        h.engine.calendarPageClosed()
        #expect(h.activities.releases == before + 1)
    }

    @Test func aSecondCloseDoesNothing() {
        let h = openedPage()
        h.engine.calendarPageClosed()
        let releases = h.activities.releases
        h.engine.calendarPageClosed()
        #expect(h.activities.releases == releases)
    }

    @Test func reopeningReadsTheEventsAgain() {
        let h = openedPage()
        h.engine.calendarPageClosed()
        let reads = h.calendarWriter.eventReads.count
        h.engine.calendarPageOpened()
        _ = h.engine.calendarPage(.containing(day(2026, 1, 5, 12), kind: .month, calendar: h.engine.calendar))
        #expect(h.calendarWriter.eventReads.count == reads + 1)
    }
}
