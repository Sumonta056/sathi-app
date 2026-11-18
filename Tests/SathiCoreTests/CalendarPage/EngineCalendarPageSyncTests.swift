import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine calendar page sync")
struct EngineCalendarPageSyncTests {
    private final class Counter {
        var builds = 0
    }

    private func event(_ id: String, _ from: Date) -> CalendarEventInfo {
        CalendarEventInfo(id: id, title: id, start: from, end: from.addingTimeInterval(3600), calendarID: "work")
    }

    @Test func closedPageDoesNotListen() {
        let h = EngineHarness(at: day(2026, 3, 4, 12))
        #expect(!h.calendarChanges.isListening)
        #expect(h.calendarChanges.starts == 0)
    }

    @Test func openStartsOnceAndCloseStops() {
        let h = EngineHarness(at: day(2026, 3, 4, 12))
        h.engine.calendarPageOpened()
        h.engine.calendarPageOpened()
        #expect(h.calendarChanges.starts == 1)
        #expect(h.calendarChanges.isListening)
        h.engine.calendarPageClosed()
        #expect(h.calendarChanges.stops == 1)
        #expect(!h.calendarChanges.isListening)
    }

    @Test func changeWhileOpenRebuildsTheMemo() {
        let h = EngineHarness(at: day(2026, 3, 4, 12))
        let range = CalendarPageRange.containing(day(2026, 2, 18, 12), kind: .week, calendar: h.engine.calendar)
        let memo = RangeMemo<CalendarPageRange, CalendarPageData>()
        let c = Counter()
        let read = {
            memo.value(range, end: range.interval.end, engine: h.engine) { e, r in
                c.builds += 1
                return e.calendarPageBase(r)
            }
        }
        h.engine.calendarPageOpened()
        #expect(read().blocks.isEmpty)
        #expect(read().blocks.isEmpty)
        #expect(c.builds == 1)
        h.calendarWriter.eventsValue = [event("Planning", day(2026, 2, 18, 10))]
        h.calendarChanges.fire()
        let data = read()
        #expect(c.builds == 2)
        #expect(data.blocks.map(\.title) == ["Planning"])
    }

    @Test func changeMarksTrackerEventsStale() {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([], mode: .logAndTell)
        h.start("Spec", minutes: 300, quiet: true)
        h.engine.calendarPageOpened()
        let review = meeting("m2", "Review", from: wed(14), to: wed(14, 30))
        h.calendarWriter.eventsValue = [review]
        h.calendarChanges.fire()
        h.clock.now = wed(14)
        h.engine.tick()
        #expect(h.running?.sourceEventID == "m2")
        #expect(h.running?.start == wed(14))
        #expect(h.running?.text == "Review")
        #expect(h.saved.map(\.text) == ["Spec"])
        #expect(h.saved.first?.end == wed(14))
    }

    @Test func engineStopRemovesTheListener() {
        let h = EngineHarness(at: day(2026, 3, 4, 12))
        h.engine.calendarPageOpened()
        h.engine.stop()
        #expect(!h.calendarChanges.isListening)
    }

    @Test func openingAddsNoTimer() {
        let h = EngineHarness(at: day(2026, 3, 4, 12))
        let before = h.engine.nextTickDelay()
        h.engine.calendarPageOpened()
        #expect(h.engine.nextTickDelay() == before)
    }

    @Test func afterCloseAFireDoesNothing() {
        let h = EngineHarness(at: day(2026, 3, 4, 12))
        let range = CalendarPageRange.containing(day(2026, 2, 18, 12), kind: .week, calendar: h.engine.calendar)
        let memo = RangeMemo<CalendarPageRange, Int>()
        let c = Counter()
        let read = {
            _ = memo.value(range, end: range.interval.end, engine: h.engine) { _, _ in
                c.builds += 1
                return 0
            }
        }
        h.engine.calendarPageOpened()
        h.engine.calendarPageClosed()
        read()
        let calls = h.calendarWriter.calendarsCalls
        h.calendarChanges.fire()
        read()
        #expect(c.builds == 1)
        #expect(h.calendarWriter.calendarsCalls == calls)
    }
}
