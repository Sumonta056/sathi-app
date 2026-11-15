import Foundation
@testable import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar to-do chip")
struct CalendarTodoChipTests {
    private func block(_ id: String = "a", title: String = "Call Rina", allDay: Bool = false) -> CalendarBlock {
        let start = day(2026, 3, 4, 15)
        return CalendarBlock(
            id: "t-" + id, title: title,
            interval: DateInterval(start: start, end: start), style: .todo(colorHex: 0xE58CF5),
            source: .todo(id), isAllDay: allDay, activityIDs: []
        )
    }

    private func chip(_ h: EngineHarness, _ block: CalendarBlock) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(CalendarTodoChip(block: block), h).inspect()
    }

    @Test func chipShowsTheTitle() throws {
        let sut = try chip(EngineHarness(), block())
        #expect(throws: Never.self) { try sut.find(text: "Call Rina") }
    }

    @Test func chipHasATickCircleWithAnAccessibleName() throws {
        let sut = try chip(EngineHarness(), block())
        let tick = try sut.find(viewWithAccessibilityIdentifier: "calendar.todo.done.a")
        #expect(throws: Never.self) { try tick.button() }
        #expect(try tick.accessibilityLabel().string() == "Mark done")
    }

    @Test func tickMarksTheTodoDone() throws {
        let h = EngineHarness.withCalendarTodos(lists: [makeTodoList("inbox")], todos: [makeTodo("a")])
        try chip(h, block()).find(viewWithAccessibilityIdentifier: "calendar.todo.done.a").button().tap()
        #expect(h.todos.calls == [.doneSet("a", true)])
    }

    @Test func tickOnOneChipLeavesOtherTodosAlone() throws {
        let h = EngineHarness.withCalendarTodos(lists: [makeTodoList("inbox")], todos: [makeTodo("a"), makeTodo("b")])
        try chip(h, block("b", title: "Other")).find(viewWithAccessibilityIdentifier: "calendar.todo.done.b").button().tap()
        #expect(h.todos.calls == [.doneSet("b", true)])
    }

    @Test func allDayRowShowsADateOnlyTodoChip() throws {
        let h = EngineHarness()
        let key = DayKey(day(2026, 3, 4, 12), calendar: h.engine.rangeCalendar)
        let row = CalendarAllDayRow(days: [key], blocks: [block(allDay: true)], categories: [], calendar: h.engine.rangeCalendar)
        let sut = try hosted(row, h).inspect()
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "calendar.todo.chip.a") }
        #expect(throws: Never.self) { try sut.find(text: "Call Rina") }
    }

    @Test func shownListHasAToDoListsGroup() async throws {
        let h = EngineHarness.withCalendarTodos(lists: [makeTodoList("inbox", "Inbox")], todos: [])
        await h.loadTodos()
        let sut = try hosted(CalendarShownList(), h).inspect()
        #expect(throws: Never.self) { try sut.find(text: "TO-DO LISTS") }
        #expect(throws: Never.self) { try sut.find(text: "Inbox") }
    }

    @Test func aTapOnATodoListHidesItsChips() async throws {
        let h = EngineHarness.withCalendarTodos(lists: [makeTodoList("inbox", "Inbox")], todos: [])
        await h.loadTodos()
        let sut = try hosted(CalendarShownList(), h).inspect()
        try sut.find(viewWithAccessibilityIdentifier: "calendar.shown.inbox").button().tap()
        #expect(h.engine.data.prefs.calendarPage.hiddenCalendarIDs == ["inbox"])
    }
}
