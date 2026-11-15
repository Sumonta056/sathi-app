import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoDueActions")
struct EngineTodoDueActionsTests {
    private let report = makeTodo("a", "Write report", due: timedDue(10, 30))

    private func due(running: ActivityDraft? = ActivityDraft(text: "Code review", length: .minutes(120))) async -> EngineHarness {
        let h = await EngineHarness.todoTracker(todos: [report], running: running)
        h.advance(minutes: 30)
        return h
    }

    @Test func laterKeepsTheRunningActivityAndChangesNothing() async {
        let h = await due()
        let before = h.running
        h.engine.closeTrackerPrompt()
        #expect(h.promptKind == nil)
        #expect(h.running == before)
        #expect(h.saved.isEmpty)
        #expect(h.todos.calls.isEmpty)
    }

    @Test func switchEndsTheRunningActivityAndStartsTheTodo() async {
        let h = await due()
        let draft = ActivityDraft(text: "Write report", category: "Coding", length: .minutes(30))
        #expect(h.engine.startTodo("a", draft: draft))
        #expect(h.saved.map(\.text) == ["Code review"])
        #expect(h.saved.first?.end == day(2026, 3, 4, 10, 30))
        #expect(h.running?.text == "Write report")
        #expect(h.running?.todoID == "a")
        #expect(h.promptKind == nil)
        #expect(h.todos.calls.isEmpty)
    }

    @Test func startItWithNothingRunningStartsTheTodo() async {
        let h = await due(running: nil)
        #expect(h.engine.startTodo("a", draft: ActivityDraft(text: "Write report")))
        #expect(h.running?.text == "Write report")
        #expect(h.running?.todoID == "a")
        #expect(h.saved.isEmpty)
    }

    @Test func startItHonoursTheSwitchTime() async {
        let h = await due()
        let at = day(2026, 3, 4, 10, 20)
        #expect(h.engine.startTodo("a", draft: ActivityDraft(text: "Write report"), switchAt: at))
        #expect(h.saved.first?.end == at)
        #expect(h.running?.start == at)
    }

    @Test func startTodoRefusesBlankText() async {
        let h = await due()
        #expect(!h.engine.startTodo("a", draft: ActivityDraft(text: "  ")))
        #expect(h.running?.text == "Code review")
        #expect(h.running?.todoID == nil)
    }

    @Test func doneMarksTheTodoDoneAndClosesThePrompt() async {
        let h = await due()
        h.engine.doneTodo("a")
        #expect(h.todos.calls == [.doneSet("a", true)])
        #expect(h.promptKind == nil)
        #expect(h.running?.text == "Code review")
        #expect(h.running?.todoID == nil)
    }

    @Test func doneLogsNoActivity() async {
        let h = await due(running: nil)
        h.engine.doneTodo("a")
        #expect(h.saved.isEmpty)
        #expect(h.running == nil)
    }

    @Test func doneRefreshesTheCache() async {
        let h = await due()
        h.todos.todosValue = [makeTodo("a", "Write report", due: timedDue(10, 30), done: true, doneAt: day(2026, 3, 4, 10, 30))]
        h.engine.doneTodo("a")
        await h.engine.todoRuntime.refreshTask?.value
        #expect(h.engine.todoSnapshot.open.isEmpty)
    }

    @Test func doneFromTheQuickPanelWorksWithNoPromptOpen() async {
        let h = await EngineHarness.todoTracker(todos: [report])
        h.engine.doneTodo("a")
        #expect(h.todos.calls == [.doneSet("a", true)])
        #expect(h.running?.text == "Code review")
    }

    @Test func noWriteWhenTheTodosAreOff() async {
        let h = await EngineHarness.todoTracker(todos: [report])
        h.engine.data.prefs.todos.isOn = false
        h.engine.doneTodo("a")
        #expect(h.todos.calls.isEmpty)
    }

    @Test func thePromptStateListsTheDueTodoWithTheRunningActivity() async {
        let h = await due()
        let s = h.engine.trackerPromptState(.todoDue)
        #expect(s?.todos.map(\.title) == ["Write report"])
        #expect(s?.running?.text == "Code review")
        #expect(h.engine.trackerPromptState(.whatNow) == nil)
    }
}
