import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine calendar page groups and narrow lanes")
struct EngineCalendarPageGroupTests {
    private let rows = [
        Activity(text: "Mail", category: "Office", start: day(2026, 3, 4, 10), end: day(2026, 3, 4, 10, 5)),
        Activity(text: "Code", category: "Work", start: day(2026, 3, 4, 10, 5), end: day(2026, 3, 4, 10, 12)),
        Activity(text: "Inside", start: day(2026, 3, 4, 14, 5), end: day(2026, 3, 4, 14, 40))
    ]

    private func harness() -> EngineHarness {
        let h = EngineHarness(at: day(2026, 3, 4, 18), activities: InMemoryActivityStore(activities: rows)) { $0.prefs.tracker.isOn = true }
        h.calendarWriter.eventsValue = [
            CalendarEventInfo(id: "p", title: "Plan", start: day(2026, 3, 4, 14), end: day(2026, 3, 4, 15), calendarID: "work")
        ]
        return h
    }

    private func range(_ h: EngineHarness) -> CalendarPageRange {
        .containing(day(2026, 3, 4, 12), kind: .day, calendar: h.engine.calendar)
    }

    @Test func narrowShapesReachTheCachedLayout() {
        let h = harness()
        let narrow: Set = [CalendarLaneShape(depth: 0, lanes: 1)]
        let data = h.engine.calendarPage(range(h), minimumMinutes: 26, narrow: narrow)
        #expect(data.placedNarrow == narrow)
        let host = data.placed[DayKey(day(2026, 3, 4), calendar: h.engine.calendar)]?.first { $0.block.title == "Plan" }
        #expect(host?.kidsShown == false)
        #expect(host?.children.map(\.block.title) == ["Inside"])
    }

    @Test func aGroupBlockHasItsTimeAndSpokenText() throws {
        let h = harness()
        let data = h.engine.calendarPage(range(h), minimumMinutes: 26)
        let placed = try #require(data.placed[DayKey(day(2026, 3, 4), calendar: h.engine.calendar)])
        let group = try #require(placed.first { $0.block.group != nil })
        let start = day(2026, 3, 4, 10)
        let end = day(2026, 3, 4, 10, 12)
        #expect(data.texts[group.block.id]?.time == Fmt.shortRange(start, end, calendar: h.engine.calendar))
        #expect(data.texts[group.block.id]?.spoken == Copywriter.calendarBlockSpoken(group.block.title, start, end, calendar: h.engine.calendar))
    }

    @Test func shownIDsHoldGroupBlocksSoTheHoverCardStaysOpen() throws {
        let h = harness()
        let data = h.engine.calendarPage(range(h), minimumMinutes: 26)
        let group = try #require(data.placed.values.flatMap { $0 }.first { $0.block.group != nil })
        #expect(data.shownIDs.contains(group.block.id))
        #expect(data.shownIDs.isSuperset(of: data.blocks.map(\.id)))
    }
}
