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

    private func chip(_ h: EngineHarness, _ block: CalendarBlock, pill: Bool = false) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(CalendarTodoChip(block: block, isPill: pill), h).inspect()
    }

    @Test func chipShowsTheTitle() throws {
        let sut = try chip(EngineHarness(), block())
        #expect(throws: Never.self) { try sut.find(text: "Call Rina") }
    }

    private func column(_ h: EngineHarness, _ block: CalendarBlock) throws -> InspectableView<ViewType.ClassifiedView> {
        let key = DayKey(day(2026, 3, 4, 12), calendar: h.engine.rangeCalendar)
        var laid = CalendarLaidBlock(block: block, span: block.interval, half: .plan)
        laid.top = 540
        laid.bottom = 540
        let grid = CalendarGridLayout(rows: [], days: [key: [laid]], height: 1440, pointsPerMinute: 1)
        let column = CalendarSplitColumn(
            day: key, kind: .day, blocks: [laid], grid: grid, width: 500, now: nil, calendar: h.engine.rangeCalendar, categories: []
        )
        return try hosted(column, h).inspect()
    }

    @Test func pillShowsTheTitleAndTheDueTime() throws {
        let h = EngineHarness()
        let sut = try chip(h, block(), pill: true)
        let due = Copywriter.trackerClock(day(2026, 3, 4, 15), calendar: h.engine.rangeCalendar)
        #expect(throws: Never.self) { try sut.find(text: "Call Rina") }
        #expect(throws: Never.self) { try sut.find(text: due) }
    }

    @Test func allDayPillShowsNoDueTime() throws {
        let h = EngineHarness()
        let sut = try chip(h, block(allDay: true), pill: true)
        let due = Copywriter.trackerClock(day(2026, 3, 4, 15), calendar: h.engine.rangeCalendar)
        #expect(throws: (any Error).self) { try sut.find(text: due) }
    }

    @Test func dayColumnDrawsADueLineThatNeverTakesClicks() throws {
        let sut = try column(EngineHarness(), block())
        let line = try sut.find(viewWithAccessibilityIdentifier: "calendar.todo.line.a")
        #expect(try line.allowsHitTesting() == false)
    }

    @Test func dayColumnShowsThePillAboveTheLine() throws {
        let sut = try column(EngineHarness(), block())
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "calendar.todo.chip.a") }
        #expect(throws: Never.self) { try sut.find(text: "Call Rina") }
    }

    @Test func tickInTheDayColumnMarksTheTodoDone() throws {
        let h = EngineHarness.withCalendarTodos(lists: [makeTodoList("inbox")], todos: [makeTodo("a")])
        try column(h, block()).find(viewWithAccessibilityIdentifier: "calendar.todo.done.a").button().tap()
        #expect(h.todos.calls == [.doneSet("a", true)])
    }

    @Test func plainChipKeepsItsLookWithNoDueTime() throws {
        let h = EngineHarness()
        let sut = try chip(h, block())
        let due = Copywriter.trackerClock(day(2026, 3, 4, 15), calendar: h.engine.rangeCalendar)
        #expect(throws: (any Error).self) { try sut.find(text: due) }
    }

    @Test func pillMetricsMatchTheDesignAndChipsKeepTheirs() {
        #expect(UIMetrics.calendarTodoPillHeight == 22)
        #expect(UIMetrics.calendarTodoPillFont == 12)
        #expect(UIMetrics.calendarChipHeight == 18)
        #expect(UIMetrics.calendarChipFont == 10)
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
