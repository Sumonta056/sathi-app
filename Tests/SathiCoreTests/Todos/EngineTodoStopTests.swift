import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoStop")
struct EngineTodoStopTests {
    @Test func startAfterAStopThatDroppedALoadReadsAgain() async {
        let h = EngineHarness { $0.prefs.todos.isOn = true }
        h.todos.listsValue = [makeTodoList("inbox")]
        h.todos.todosValue = [makeTodo("a", list: "inbox")]
        h.todos.holdsReads = true
        let load = Task { @MainActor in await h.engine.refreshTodosNow() }
        await waitUntil { h.todos.suspendedReads == 1 }
        h.todos.holdsReads = false
        h.engine.stop()
        h.todos.releaseReads()
        await load.value
        #expect(h.engine.todoSnapshot == .empty)
        h.engine.start()
        await h.engine.todoRuntime.refreshTask?.value
        #expect(h.engine.todoSnapshot.open.map(\.id) == ["a"])
    }

    @Test func stopMarksTheCacheStale() async {
        let h = EngineHarness { $0.prefs.todos.isOn = true }
        h.todos.listsValue = [makeTodoList("inbox")]
        h.engine.start()
        await h.engine.todoRuntime.refreshTask?.value
        #expect(!h.engine.todoRuntime.stale)
        h.engine.stop()
        #expect(h.engine.todoRuntime.stale)
    }

    @Test func turningOffClearsTheLoadedRevision() async {
        let h = EngineHarness { $0.prefs.todos.isOn = true }
        h.todos.listsValue = [makeTodoList("inbox")]
        h.engine.start()
        await h.engine.todoRuntime.refreshTask?.value
        #expect(h.engine.todoRuntime.loadedRevision != nil)
        h.engine.data.prefs.todos.isOn = false
        #expect(h.engine.todoRuntime.loadedRevision == nil)
        #expect(h.engine.todoAccess == .notAsked)
    }
}
