@testable import SathiCore
import SathiTestSupport
@testable import SathiUI
import Testing

@MainActor
@Suite("Quick to-do done write")
struct QuickTodoDoneTests {
    private let report = makeTodo("a", "Write report", due: timedDue(10, 30))
    private let closed = makeTodo("a", "Write report", due: timedDue(10, 30), done: true, doneAt: day(2026, 3, 4, 10, 30))

    private func written(_ h: EngineHarness, _ gate: TodoFinishingGate) async -> TodoFinishing {
        let sut = TodoFinishing(wait: { [gate] in await gate.wait($0) }, write: { _ in })
        sut.bind(QuickTodoDone.write(h.engine, sut))
        sut.tick("a")
        await waitUntil { gate.waiting == 1 }
        gate.release()
        await waitUntil { sut.phase("a") == .leaving && gate.waiting == 1 }
        h.todos.holdsReads = true
        gate.release()
        await waitUntil { h.todos.suspendedReads == 1 }
        await gate.settle()
        return sut
    }

    @Test func aClosedTodoStaysFoldedWhileItsRefreshIsInFlight() async {
        let h = await EngineHarness.todoTracker(todos: [report], running: nil)
        h.todos.todosValue = [closed]
        let gate = TodoFinishingGate()
        let sut = await written(h, gate)
        #expect(h.todos.calls == [.doneSet("a", true)])
        #expect(sut.phase("a") == .leaving)
        h.todos.releaseReads()
        await gate.settle()
        #expect(h.engine.todoSnapshot.open.isEmpty)
        #expect(sut.phase("a") == .leaving)
    }

    @Test func aTodoStillOpenComesBackOnlyAfterTheFreshSnapshot() async {
        let h = await EngineHarness.todoTracker(todos: [report], running: nil)
        let gate = TodoFinishingGate()
        let sut = await written(h, gate)
        #expect(sut.phase("a") == .leaving)
        h.todos.releaseReads()
        await gate.settle()
        #expect(h.engine.todoSnapshot.open.map(\.id) == ["a"])
        #expect(sut.phase("a") == nil)
    }

    @Test func aFailedWriteBringsTheRowBackAfterTheRefresh() async {
        let h = await EngineHarness.todoTracker(todos: [report], running: nil)
        h.todos.nextResult = .failed
        let gate = TodoFinishingGate()
        let sut = await written(h, gate)
        h.todos.releaseReads()
        await gate.settle()
        #expect(sut.phase("a") == nil)
    }
}
