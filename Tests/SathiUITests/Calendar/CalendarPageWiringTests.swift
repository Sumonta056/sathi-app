import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar page wiring")
struct CalendarPageWiringTests {
    typealias Fix = CalendarMergeSupport

    private final class FocusBox {
        var focus = CalendarPageFocus(
            editing: CalendarActivityEdit(day: DayKey(day(2026, 3, 4, 12), calendar: .current), target: .activity(Fix.first.id))
        )
        var binding: Binding<CalendarPageFocus> { Binding(get: { self.focus }, set: { self.focus = $0 }) }
    }

    private func blocks(_ h: EngineHarness) -> [CalendarBlock] {
        h.engine.calendarPage(Fix.range(h)).blocks
    }

    private func nextDay(_ h: EngineHarness) -> CalendarPageRange {
        .containing(day(2026, 3, 5, 12), kind: .day, calendar: h.engine.rangeCalendar)
    }

    @Test func aRangeChangeClearsTheSelectionTheErrorTheFocusAndUndo() throws {
        let h = Fix.harness([Fix.first, Fix.second])
        let box = Fix.Box(), focus = FocusBox()
        box.selected = [Fix.first.id]
        box.error = "old"
        var clears = 0
        let reset = CalendarRangeReset(
            range: Fix.range(h), focus: focus.binding, selected: box.selectedBinding, error: box.errorBinding
        ) { clears += 1 }
        try Color.clear.modifier(reset).inspect().callOnChange(newValue: nextDay(h))
        #expect(box.selected.isEmpty)
        #expect(box.error == nil)
        #expect(focus.focus.editing == nil)
        #expect(focus.focus.popover == nil)
        #expect(clears == 1)
    }

    @Test func goneRowsLeaveTheSelectionAndClearTheError() throws {
        let h = Fix.harness([Fix.first, Fix.second])
        let box = Fix.Box()
        box.selected = [Fix.first.id, Fix.second.id]
        box.error = "stale"
        let prune = CalendarSelectionPrune(blocks: blocks(h), selected: box.selectedBinding, error: box.errorBinding)
        let left = blocks(h).filter { $0.title != "Review" }
        try Color.clear.modifier(prune).inspect().callOnChange(newValue: left)
        #expect(box.selected == [Fix.first.id])
        #expect(box.error == nil)
    }

    @Test func aChangeThatKeepsTheSelectionKeepsTheError() throws {
        let h = Fix.harness([Fix.first, Fix.second])
        let box = Fix.Box()
        box.selected = [Fix.first.id]
        box.error = "still true"
        let prune = CalendarSelectionPrune(blocks: blocks(h), selected: box.selectedBinding, error: box.errorBinding)
        try Color.clear.modifier(prune).inspect().callOnChange(newValue: blocks(h))
        #expect(box.selected == [Fix.first.id])
        #expect(box.error == "still true")
    }

    @Test func thePageResetsOnARangeChange() throws {
        let h = Fix.harness([Fix.first])
        #expect(throws: Never.self) {
            try hosted(CalendarPage(), h).inspect().find(ViewType.VStack.self).modifier(CalendarRangeReset.self)
        }
    }

    @Test func thePagePrunesOnABlockChange() throws {
        let h = Fix.harness([Fix.first])
        h.engine.refreshCalendarAccess()
        #expect(throws: Never.self) {
            try hosted(CalendarPage(), h).inspect().find(ViewType.HStack.self).modifier(CalendarSelectionPrune.self)
        }
    }

    @Test func thePageRangeChangeClearsTheEngineUndo() throws {
        let h = Fix.harness([Fix.first, Fix.second])
        #expect(h.engine.mergeActivities([Fix.first.id, Fix.second.id]) == .merged(Fix.first.id))
        #expect(h.engine.mergeUndo != nil)
        let reset = try hosted(CalendarPage(), h).inspect().find(ViewType.VStack.self).modifier(CalendarRangeReset.self)
        try reset.actualView().clearUndo()
        #expect(h.engine.mergeUndo == nil)
    }
}
