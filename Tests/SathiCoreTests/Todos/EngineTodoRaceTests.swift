import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoRace")
struct EngineTodoRaceTests {
    private func harness() -> EngineHarness {
        let h = EngineHarness { $0.prefs.todos.isOn = true }
        h.todos.listsValue = [makeTodoList("inbox")]
        h.todos.todosValue = [makeTodo("a", list: "inbox")]
        return h
    }

    private func startHeldLoad(_ h: EngineHarness) async -> Task<Void, Never> {
        h.todos.holdsReads = true
        let load = Task { @MainActor in await h.engine.refreshTodosNow() }
        while h.todos.suspendedReads < 1 {
            await Task.yield()
        }
        h.todos.holdsReads = false
        return load
    }

    @Test func aLoadFinishingAfterTurnOffDoesNotApply() async {
        let h = harness()
        let load = await startHeldLoad(h)
        h.engine.data.prefs.todos.isOn = false
        h.todos.releaseReads()
        await load.value
        #expect(h.engine.todoSnapshot == .empty)
    }

    @Test func anOlderLoadFinishingLaterDoesNotOverwriteANewerOne() async {
        let h = harness()
        let load = await startHeldLoad(h)
        h.todos.todosValue.append(makeTodo("c", list: "inbox"))
        h.todos.revision += 1
        await h.engine.refreshTodosNow()
        #expect(Set(h.engine.todoSnapshot.open.map(\.id)) == ["a", "c"])
        h.todos.releaseReads()
        await load.value
        #expect(Set(h.engine.todoSnapshot.open.map(\.id)) == ["a", "c"])
    }

    @Test func aLoadFinishingAfterStopDoesNotApply() async {
        let h = harness()
        let load = await startHeldLoad(h)
        h.engine.stop()
        h.todos.releaseReads()
        await load.value
        #expect(h.engine.todoSnapshot == .empty)
    }

    @Test func changingAskWhenDueOrAccountReadsNothing() async {
        let h = harness()
        h.engine.start()
        await h.engine.todoRuntime.refreshTask?.value
        let reads = h.todos.readRequests.count
        h.engine.data.prefs.todos.askWhenDue = false
        h.engine.data.prefs.todos.newListAccountID = "icloud"
        await h.engine.todoRuntime.refreshTask?.value
        await h.engine.refreshTodosNow()
        #expect(h.todos.readRequests.count == reads)
    }

    @Test func turningOffResetsAccessAndTheLoadedRevision() async {
        let h = harness()
        h.engine.start()
        await h.engine.todoRuntime.refreshTask?.value
        h.engine.data.prefs.todos.isOn = false
        #expect(h.engine.todoAccess == .notAsked)
        #expect(h.engine.todoRuntime.loadedRevision == nil)
        let reads = h.todos.readRequests.count
        h.engine.data.prefs.todos.isOn = true
        await h.engine.todoRuntime.refreshTask?.value
        #expect(h.todos.readRequests.count == reads + 1)
        #expect(h.engine.todoAccess == .allowed)
    }
}
