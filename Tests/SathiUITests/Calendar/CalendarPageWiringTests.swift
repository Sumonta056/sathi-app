import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

private let write = Activity(text: "Write", category: "Coding", start: day(2026, 3, 4, 10), end: day(2026, 3, 4, 10, 30))

@MainActor
@Suite("Calendar page wiring")
struct CalendarPageWiringTests {
    private final class Box {
        var focus = CalendarPageFocus(
            editing: CalendarActivityEdit(day: DayKey(day(2026, 3, 4, 12), calendar: .current), target: .activity(write.id))
        )
        var failure: String? = "old"
        var focusBinding: Binding<CalendarPageFocus> { Binding(get: { self.focus }, set: { self.focus = $0 }) }
        var failureBinding: Binding<String?> { Binding(get: { self.failure }, set: { self.failure = $0 }) }
    }

    private func harness() -> EngineHarness {
        EngineHarness(at: day(2026, 3, 4, 12), activities: InMemoryActivityStore(activities: [write])) { $0.prefs.tracker.isOn = true }
    }

    private func range(_ h: EngineHarness, _ date: Date = day(2026, 3, 4, 12)) -> CalendarPageRange {
        .containing(date, kind: .day, calendar: h.engine.rangeCalendar)
    }

    @Test func aRangeChangeClearsTheFocusAndTheErrorLine() throws {
        let h = harness()
        let box = Box()
        let reset = CalendarRangeReset(range: range(h), focus: box.focusBinding, failure: box.failureBinding)
        try Color.clear.modifier(reset).inspect().callOnChange(newValue: range(h, day(2026, 3, 5, 12)))
        #expect(box.focus.editing == nil)
        #expect(box.focus.popover == nil)
        #expect(box.failure == nil)
    }

    @Test func thePageResetsOnARangeChange() throws {
        let h = harness()
        #expect(throws: Never.self) {
            try hosted(CalendarPage(), h).inspect().find(ViewType.VStack.self).modifier(CalendarRangeReset.self)
        }
    }

    @Test func thePageAsksTheEngineForTheSplitLayout() throws {
        let h = harness()
        h.engine.refreshCalendarAccess()
        let grid = try hosted(CalendarPage(range: range(h)), h).inspect().find(CalendarSplitGrid.self).actualView()
        #expect(grid.data.grid != nil)
        #expect(grid.data.grid?.days.values.joined().contains { $0.block.title == "Write" } == true)
    }

    @Test func dayGetsTheCompactHeightOfAShortDayCard() throws {
        let h = harness()
        h.engine.refreshCalendarAccess()
        let grid = try hosted(CalendarPage(range: range(h)), h).inspect().find(CalendarSplitGrid.self).actualView()
        let write = try #require(grid.data.grid?.days.values.joined().first { $0.block.title == "Write" })
        #expect(write.bottom - write.top >= UIMetrics.calendarDayCompactMinHeight)
        #expect(write.bottom - write.top < UIMetrics.calendarDayCardMinHeight)
    }
}
