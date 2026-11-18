import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine calendar page placed blocks")
struct EngineCalendarPagePlacedTests {
    private final class Counter {
        var builds = 0
    }

    private func harness() -> EngineHarness {
        let h = EngineHarness(at: day(2026, 3, 4, 12))
        h.calendarWriter.eventsValue = [
            CalendarEventInfo(id: "a", title: "A", start: day(2026, 3, 4, 9), end: day(2026, 3, 4, 9, 8), calendarID: "work"),
            CalendarEventInfo(id: "b", title: "B", start: day(2026, 3, 4, 9, 8), end: day(2026, 3, 4, 9, 16), calendarID: "work"),
            CalendarEventInfo(id: "c", title: "C", start: day(2026, 3, 5, 9), end: day(2026, 3, 5, 10), calendarID: "work")
        ]
        return h
    }

    private func range(_ h: EngineHarness, _ kind: ReportRange) -> CalendarPageRange {
        .containing(day(2026, 3, 4, 12), kind: kind, calendar: h.engine.calendar)
    }

    @Test(arguments: [ReportRange.day, .week])
    func pageDataHoldsTheLayoutOfEveryDay(_ kind: ReportRange) {
        let h = harness()
        let data = h.engine.calendarPage(range(h, kind), minimumMinutes: 26)
        #expect(data.placedMinimumMinutes == 26)
        #expect(data.placed.keys.sorted() == data.range.days)
        for key in data.range.days {
            let column = CalendarPageDay.interval(of: key, calendar: h.engine.calendar)
            #expect(data.placed[key] == CalendarBlockLayout.place(data.blocks, within: column, minimumMinutes: 26))
        }
        let wed = DayKey(day(2026, 3, 4), calendar: h.engine.calendar)
        #expect(data.placed[wed]?.map(\.displaySpan.start) == [day(2026, 3, 4, 9), day(2026, 3, 4, 9, 26)])
    }

    @Test func monthHasNoGridLayout() {
        let h = harness()
        #expect(h.engine.calendarPage(range(h, .month), minimumMinutes: 26).placed.isEmpty)
    }

    @Test func memoReturnsTheSameLayoutWithoutBuildingAgain() {
        let h = harness()
        let r = range(h, .week)
        let memo = RangeMemo<CalendarPageRange, CalendarPageData>()
        let c = Counter()
        let read = {
            memo.value(r, end: r.interval.end, engine: h.engine) { e, r in
                c.builds += 1
                return e.calendarPage(r, minimumMinutes: 26)
            }
        }
        let first = read()
        let second = read()
        #expect(c.builds == 1)
        #expect(first.placed == second.placed)
        #expect(!first.placed.isEmpty)
    }
}
