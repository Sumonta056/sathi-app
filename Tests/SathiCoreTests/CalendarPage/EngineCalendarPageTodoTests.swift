import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine calendar page to-dos")
struct EngineCalendarPageTodoTests {
    private let lists = [makeTodoList("inbox", "Inbox"), makeTodoList("errands", "Errands")]

    private func timed(_ id: String, list: String = "inbox", hour: Int = 15) -> Todo {
        makeTodo(id, "Task " + id, list: list, due: TodoDue(date: day(2026, 3, 4, hour), hasTime: true))
    }

    private func dateOnly(_ id: String, list: String = "inbox") -> Todo {
        makeTodo(id, "Task " + id, list: list, due: TodoDue(date: day(2026, 3, 4, 9), hasTime: false))
    }

    private func loaded(_ todos: [Todo], hidden: Set<String> = [], on: Bool = true) async -> EngineHarness {
        let h = EngineHarness.withCalendarTodos(lists: lists, todos: todos, todosOn: on, hiddenCalendarIDs: hidden)
        await h.loadTodos()
        return h
    }

    private func sources(_ blocks: [CalendarBlock]) -> [CalendarBlockSource] { blocks.map(\.source) }

    @Test func timedTodoShowsAsAChipInTheGrid() async {
        let h = await loaded([timed("a")])
        let data = h.engine.calendarPage(h.calendarDay())
        #expect(sources(data.blocks) == [.todo("a")])
        #expect(data.blocks.first?.interval.start == day(2026, 3, 4, 15))
        #expect(data.allDay.isEmpty)
    }

    @Test func dateOnlyTodoShowsInTheAllDayRow() async {
        let h = await loaded([dateOnly("d")])
        let data = h.engine.calendarPage(h.calendarDay())
        #expect(sources(data.allDay) == [.todo("d")])
        #expect(data.blocks.isEmpty)
    }

    @Test func todoChipUsesTheListColor() async {
        let h = await loaded([timed("a")])
        let data = h.engine.calendarPage(h.calendarDay())
        #expect(data.blocks.first?.style == .todo(colorHex: 0xFF3B30))
    }

    @Test func todoOnAnotherDayIsNotInThisDay() async {
        let other = makeTodo("x", due: TodoDue(date: day(2026, 3, 6, 10), hasTime: true))
        let h = await loaded([other])
        let data = h.engine.calendarPage(h.calendarDay())
        #expect(data.blocks.isEmpty && data.allDay.isEmpty)
        let week = h.engine.calendarPage(.containing(day(2026, 3, 4, 12), kind: .week, calendar: h.engine.calendar))
        #expect(sources(week.blocks) == [.todo("x")])
    }

    @Test func doneTodoDoesNotShow() async {
        let done = makeTodo(
            "z", due: TodoDue(date: day(2026, 3, 4, 10), hasTime: true), done: true, doneAt: day(2026, 3, 4, 11)
        )
        let h = await loaded([done, timed("a")])
        #expect(h.engine.todoSnapshot.recentCompleted.map(\.id) == ["z"])
        #expect(sources(h.engine.calendarPage(h.calendarDay()).blocks) == [.todo("a")])
    }

    @Test func hiddenTodoListHidesItsChips() async {
        let h = await loaded([timed("a", list: "inbox"), timed("b", list: "errands", hour: 16), dateOnly("c", list: "errands")], hidden: ["errands"])
        let data = h.engine.calendarPage(h.calendarDay())
        #expect(sources(data.blocks) == [.todo("a")])
        #expect(data.allDay.isEmpty)
    }

    @Test func showingTheListAgainBringsTheChipsBack() async {
        let h = await loaded([timed("b", list: "errands")], hidden: ["errands"])
        #expect(h.engine.calendarPage(h.calendarDay()).blocks.isEmpty)
        h.engine.setCalendarShown("errands", true)
        #expect(sources(h.engine.calendarPage(h.calendarDay()).blocks) == [.todo("b")])
    }

    @Test func todosOffShowNoChips() async {
        let h = await loaded([timed("a")], on: false)
        let data = h.engine.calendarPage(h.calendarDay())
        #expect(data.blocks.isEmpty && data.allDay.isEmpty)
    }

    @Test func noReminderAccessShowsNoChips() async {
        let h = EngineHarness.withCalendarTodos(lists: lists, todos: [timed("a")])
        h.todos.access = .denied
        await h.loadTodos()
        #expect(h.engine.calendarPage(h.calendarDay()).blocks.isEmpty)
    }

    @Test func aStoreChangeShowsInThePageWithoutChangingTheRange() async {
        let h = await loaded([timed("a")])
        _ = h.engine.calendarPage(h.calendarDay())
        h.todos.todosValue = [timed("a"), timed("n", hour: 17)]
        h.todos.revision += 1
        await h.loadTodos()
        #expect(sources(h.engine.calendarPage(h.calendarDay()).blocks) == [.todo("a"), .todo("n")])
    }

    @Test func todosDoNotCountInPlannedOrTracked() async {
        let events = [CalendarEventInfo(
            id: "e", title: "Standup", start: day(2026, 3, 4, 9), end: day(2026, 3, 4, 10), calendarID: "work"
        )]
        let plain = EngineHarness(at: day(2026, 3, 4, 12))
        plain.calendarWriter.eventsValue = events
        let base = plain.engine.calendarPage(plain.calendarDay()).stats
        let h = await loaded([timed("a"), dateOnly("d")])
        h.calendarWriter.eventsValue = events
        let data = h.engine.calendarPage(h.calendarDay())
        #expect(data.blocks.count == 2)
        #expect(data.stats == base)
        #expect(data.stats.planned == 3600)
        #expect(data.stats.tracked == 0)
    }

    @Test func todosAreNeverWrittenToACalendar() async {
        let h = await loaded([timed("a")])
        _ = h.engine.calendarPage(h.calendarDay())
        #expect(h.calendarWriter.saved.isEmpty)
        #expect(h.calendarWriter.updated.isEmpty)
        #expect(h.calendarWriter.deleted.isEmpty)
    }

    @Test func tickingAChipMarksTheTodoDone() async {
        let h = await loaded([timed("a")])
        h.engine.completeCalendarTodo("a")
        #expect(h.todos.calls == [.doneSet("a", true)])
    }

    @Test func tickedTodoLeavesTheGridAfterTheReload() async {
        let h = await loaded([timed("a")])
        h.engine.completeCalendarTodo("a")
        h.todos.todosValue = [makeTodo("a", due: TodoDue(date: day(2026, 3, 4, 15), hasTime: true), done: true, doneAt: day(2026, 3, 4, 12))]
        h.todos.revision += 1
        await h.engine.todoRuntime.refreshTask?.value
        await h.loadTodos()
        #expect(h.engine.calendarPage(h.calendarDay()).blocks.isEmpty)
    }

    @Test func openingThePageReadsTheTodos() async {
        let h = EngineHarness.withCalendarTodos(lists: lists, todos: [timed("a")])
        #expect(h.engine.todoSnapshot == .empty)
        h.engine.calendarPageOpened()
        await h.engine.todoRuntime.refreshTask?.value
        #expect(h.engine.todoSnapshot.open.map(\.id) == ["a"])
    }

    @Test func openingThePageWithTodosOffReadsNothing() async {
        let h = EngineHarness.withCalendarTodos(lists: lists, todos: [timed("a")], todosOn: false)
        h.engine.calendarPageOpened()
        await h.engine.todoRuntime.refreshTask?.value
        #expect(h.todos.readRequests.isEmpty)
    }

    @Test func aFailedTickStillRefreshesFromTheStore() async {
        let h = await loaded([timed("a")])
        h.todos.nextResult = .failed
        let before = h.todos.readRequests.count
        h.engine.completeCalendarTodo("a")
        await h.engine.todoRuntime.refreshTask?.value
        #expect(h.todos.readRequests.count == before + 1)
        #expect(sources(h.engine.calendarPage(h.calendarDay()).blocks) == [.todo("a")])
    }
}
