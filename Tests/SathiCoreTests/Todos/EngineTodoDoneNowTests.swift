import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoDoneNow")
struct EngineTodoDoneNowTests {
    private let report = makeTodo("a", "Write report", due: timedDue(10, 30))
    private let closed = makeTodo("a", "Write report", due: timedDue(10, 30), done: true, doneAt: day(2026, 3, 4, 10, 30))

    @Test func itReturnsOnlyAfterTheFreshSnapshotIsApplied() async {
        let h = await EngineHarness.todoTracker(todos: [report], running: nil)
        h.todos.todosValue = [closed]
        h.todos.holdsReads = true
        var result: Bool?
        let call = Task { @MainActor in result = await h.engine.doneTodoNow("a") }
        await waitUntil { h.todos.suspendedReads == 1 }
        #expect(result == nil)
        #expect(h.engine.todoSnapshot.open.map(\.id) == ["a"])
        h.todos.releaseReads()
        await call.value
        #expect(result == true)
        #expect(h.engine.todoSnapshot.open.isEmpty)
    }

    @Test func itWritesTheTodoAndClosesTheDuePrompt() async {
        let h = await EngineHarness.todoTracker(todos: [report])
        h.advance(minutes: 30)
        #expect(h.promptKind == .todoDue)
        #expect(await h.engine.doneTodoNow("a"))
        #expect(h.todos.calls == [.doneSet("a", true)])
        #expect(h.promptKind == nil)
        #expect(h.running?.text == "Code review")
    }

    @Test func itReportsAFailedWrite() async {
        let h = await EngineHarness.todoTracker(todos: [report])
        h.todos.nextResult = .failed
        #expect(await !(h.engine.doneTodoNow("a")))
    }

    @Test func itWritesNothingWhenTheTodosAreOff() async {
        let h = await EngineHarness.todoTracker(todos: [report])
        h.engine.data.prefs.todos.isOn = false
        #expect(await !(h.engine.doneTodoNow("a")))
        #expect(h.todos.calls.isEmpty)
    }
}
