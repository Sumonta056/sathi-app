import Foundation
@testable import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar to-do popover")
struct CalendarTodoPopoverTests {
    private func block(_ id: String = "a", allDay: Bool = false) -> CalendarBlock {
        let start = day(2026, 3, 4, 15)
        return CalendarBlock(
            id: "t-" + id, title: "Call Rina",
            interval: DateInterval(start: start, end: start), style: .todo(colorHex: 0xE58CF5),
            source: .todo(id), isAllDay: allDay, activityIDs: []
        )
    }

    private func loaded(_ lists: [TodoList] = [makeTodoList("inbox")], _ todos: [Todo] = [makeTodo("a", "Call Rina")]) async -> EngineHarness {
        let h = EngineHarness.withCalendarTodos(lists: lists, todos: todos)
        await h.loadTodos()
        return h
    }

    @Test func theChipBodyIsAButtonThatDoesNotMarkDone() async throws {
        let h = await loaded()
        let sut = try hosted(CalendarTodoChip(block: block()), h).inspect()
        try sut.find(viewWithAccessibilityIdentifier: "calendar.todo.chip.a").button().tap()
        #expect(h.todos.calls.isEmpty)
    }

    @Test func thePopoverHoldsTheEditCardOfThatTodo() async throws {
        let h = await loaded()
        let sut = try hosted(CalendarTodoPopover(todoID: "a") {}, h).inspect()
        let card = try sut.find(TodoEditCard.self)
        #expect(try card.actualView().todo.id == "a")
        #expect(throws: Never.self) { try card.find(viewWithAccessibilityIdentifier: "todos.edit.save") }
    }

    @Test func aReadOnlyListShowsTheCardReadOnly() async throws {
        let h = await loaded([makeReadOnlyTodoList("ro")], [makeTodo("a", "Call Rina", list: "ro")])
        let sut = try hosted(CalendarTodoPopover(todoID: "a") {}, h).inspect()
        #expect(throws: Never.self) { try sut.find(TodoEditCard.self) }
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.edit.save")) == nil)
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.edit.delete")) == nil)
    }

    @Test func cancelClosesThePopover() async throws {
        let h = await loaded()
        var closed = 0
        let sut = try hosted(CalendarTodoPopover(todoID: "a") { closed += 1 }, h).inspect()
        try sut.find(viewWithAccessibilityIdentifier: "todos.edit.cancel").find(ViewType.Button.self, relation: .parent).tap()
        #expect(closed == 1)
    }

    @Test func saveWritesThroughTheEnginePathAndCloses() async throws {
        let h = await loaded()
        var closed = 0
        let sut = try hosted(CalendarTodoPopover(todoID: "a") { closed += 1 }, h).inspect()
        try sut.find(viewWithAccessibilityIdentifier: "todos.edit.save").find(ViewType.Button.self, relation: .parent).tap()
        await waitUntil { closed == 1 }
        #expect(closed == 1)
    }

    @Test func tickStillMarksDoneAtOnce() async throws {
        let h = await loaded()
        let sut = try hosted(CalendarTodoChip(block: block()), h).inspect()
        try sut.find(viewWithAccessibilityIdentifier: "calendar.todo.done.a").button().tap()
        #expect(h.todos.calls == [.doneSet("a", true)])
    }

    @Test func aMonthCellDrawsATodoAsAnOpenableChipWithNoTick() async throws {
        let h = await loaded()
        let key = DayKey(day(2026, 3, 4, 12), calendar: h.engine.rangeCalendar)
        let cell = CalendarMonthCell(day: key, chips: [block(allDay: true)], more: 0, tracked: 0, isToday: true, inRange: true)
        let sut = try hosted(CalendarMonthCellView(cell: cell, calendar: h.engine.rangeCalendar, categories: []) {}, h).inspect()
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "calendar.todo.chip.a") }
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "calendar.todo.done.a")) == nil)
    }

    @Test func theWholeChipIsTheOpenButton() async throws {
        let h = await loaded()
        let sut = try hosted(CalendarTodoChip(block: block()), h).inspect()
        let chip = try sut.find(viewWithAccessibilityIdentifier: "calendar.todo.chip.a")
        #expect(throws: Never.self) { try chip.button() }
        #expect(throws: Never.self) { try chip.find(viewWithAccessibilityIdentifier: "calendar.todo.done.a") }
    }

    @Test func aChipTapInTheGridNeverRunsTheSlotAction() async throws {
        let h = await loaded()
        let key = DayKey(day(2026, 3, 4, 12), calendar: h.engine.rangeCalendar)
        var laid = CalendarLaidBlock(block: block(), span: block().interval, half: .plan)
        laid.top = 540
        laid.bottom = 540
        var slots = 0
        var actions = CalendarGridActions()
        actions.slot = { _, _, _ in slots += 1 }
        let column = CalendarSplitColumn(
            day: key, kind: .day, blocks: [laid], grid: CalendarGridLayout(rows: [], days: [key: [laid]], height: 1440, pointsPerMinute: 1),
            width: 500, now: nil, calendar: h.engine.rangeCalendar, categories: [], actions: actions
        )
        let sut = try hosted(column, h).inspect()
        try sut.find(viewWithAccessibilityIdentifier: "calendar.todo.chip.a").button().tap()
        #expect(slots == 0)
        #expect(h.todos.calls.isEmpty)
    }
}
