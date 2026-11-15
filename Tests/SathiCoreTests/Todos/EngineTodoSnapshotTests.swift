import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoSnapshot")
struct EngineTodoSnapshotTests {
    private func harness(on: Bool = true, hidden: Set<String> = []) -> EngineHarness {
        let h = EngineHarness { state in
            state.prefs.todos.isOn = on
            state.prefs.todos.hiddenListIDs = hidden
        }
        h.todos.listsValue = [makeTodoList("inbox"), makeTodoList("work")]
        h.todos.todosValue = [
            makeTodo("a", list: "inbox"),
            makeTodo("b", list: "work")
        ]
        return h
    }

    private func settle(_ h: EngineHarness) async {
        await h.engine.todoRuntime.refreshTask?.value
    }

    @Test func offKeepsTheSnapshotEmptyAndReadsNothing() async {
        let h = harness(on: false)
        h.engine.start()
        await settle(h)
        await h.engine.refreshTodosNow()
        #expect(h.engine.todoSnapshot == .empty)
        #expect(h.todos.readRequests.isEmpty)
        #expect(h.todos.calls.isEmpty)
    }

    @Test func onAndAllowedLoadsListsAndTodos() async {
        let h = harness()
        h.engine.start()
        await settle(h)
        #expect(h.engine.todoAccess == .allowed)
        #expect(h.engine.todoSnapshot.lists.map(\.id) == ["inbox", "work"])
        #expect(Set(h.engine.todoSnapshot.open.map(\.id)) == ["a", "b"])
    }

    @Test func hiddenListsAreNotReadOrShown() async {
        let h = harness(hidden: ["work"])
        h.engine.start()
        await settle(h)
        #expect(h.todos.readRequests == [["inbox"]])
        #expect(h.engine.todoSnapshot.lists.map(\.id) == ["inbox"])
        #expect(h.engine.todoSnapshot.open.map(\.id) == ["a"])
    }

    @Test(arguments: [TodoAccess.denied, .notAsked])
    func noAccessKeepsTheSnapshotEmpty(_ access: TodoAccess) async {
        let h = harness()
        h.todos.access = access
        h.engine.start()
        await settle(h)
        #expect(h.engine.todoAccess == access)
        #expect(h.engine.todoSnapshot == .empty)
        #expect(h.todos.readRequests.isEmpty)
    }

    @Test func completedSinceComesFromTheRules() async {
        let h = harness()
        h.engine.start()
        await settle(h)
        let expected = TodoRules.completedSince(now: h.clock.now, calendar: h.engine.calendar)
        #expect(h.todos.completedSinceRequests == [expected])
    }

    @Test func recentCompletedAreSplitAndSortedNewestFirst() async {
        let h = harness()
        let t = h.clock.now
        h.todos.todosValue = [
            makeTodo("open", list: "inbox"),
            makeTodo("old", list: "inbox", done: true, doneAt: t.addingTimeInterval(-3600)),
            makeTodo("new", list: "inbox", done: true, doneAt: t.addingTimeInterval(-60))
        ]
        h.engine.start()
        await settle(h)
        #expect(h.engine.todoSnapshot.open.map(\.id) == ["open"])
        #expect(h.engine.todoSnapshot.recentCompleted.map(\.id) == ["new", "old"])
    }

    @Test func storeChangeRefreshesAndRequestsATick() async {
        let h = harness()
        h.engine.start()
        await settle(h)
        h.todos.todosValue.append(makeTodo("c", list: "inbox"))
        let timer = h.engine.timer
        h.calendarChanges.fire()
        await settle(h)
        #expect(h.engine.todoSnapshot.open.map(\.id).contains("c"))
        #expect(h.engine.timer !== timer)
    }

    @Test func sameContentDoesNotPublishAgain() async {
        let h = harness()
        h.engine.start()
        await settle(h)
        var publishes = 0
        let sub = h.engine.$todoSnapshot.dropFirst().sink { _ in publishes += 1 }
        h.calendarChanges.fire()
        await settle(h)
        await h.engine.refreshTodosNow()
        #expect(publishes == 0)
        sub.cancel()
    }

    @Test func changedContentPublishesOnce() async {
        let h = harness()
        h.engine.start()
        await settle(h)
        var publishes = 0
        let sub = h.engine.$todoSnapshot.dropFirst().sink { _ in publishes += 1 }
        h.todos.todosValue.append(makeTodo("c", list: "inbox"))
        h.calendarChanges.fire()
        await settle(h)
        #expect(publishes == 1)
        sub.cancel()
    }

    @Test func openingAPageWithNothingStaleReadsNothing() async {
        let h = harness()
        h.engine.start()
        await settle(h)
        let reads = h.todos.readRequests.count
        h.engine.refreshTodos()
        await settle(h)
        #expect(h.todos.readRequests.count == reads)
    }

    @Test func aStoreRevisionBumpWithoutANotificationReloads() async {
        let h = harness()
        h.engine.start()
        await settle(h)
        h.todos.todosValue.append(makeTodo("c", list: "inbox"))
        h.todos.revision += 1
        h.engine.refreshTodos()
        await settle(h)
        #expect(h.engine.todoSnapshot.open.map(\.id).contains("c"))
    }
}
