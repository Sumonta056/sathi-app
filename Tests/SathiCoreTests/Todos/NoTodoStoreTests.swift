import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("NoTodoStore")
struct NoTodoStoreTests {
    private let store = NoTodoStore()

    @Test func accessIsNotAskedAndStaysSo() async {
        #expect(store.access == .notAsked)
        #expect(await store.requestAccess() == .notAsked)
    }

    @Test func readsAreEmpty() async {
        #expect(store.accounts().isEmpty)
        #expect(store.lists().isEmpty)
        #expect(store.revision == 0)
        #expect(await store.todos(listIDs: ["a"], completedSince: .distantPast).isEmpty)
    }

    @Test func everyWriteFails() {
        let draft = TodoDraft(listID: "a", title: "Milk", notes: "", due: nil)
        let edit = TodoEdit(title: "Milk", notes: "", due: nil)
        let listDraft = TodoListDraft(name: "L", colorHex: Limits.todoListColors[0], accountID: "ic")
        #expect(store.add(draft) == .failed)
        #expect(store.update("1", edit) == .failed)
        #expect(store.setDone("1", true) == .failed)
        #expect(store.move("1", to: "b") == .failed)
        #expect(store.delete("1") == .failed)
        #expect(store.createList(listDraft) == .failed)
        #expect(store.renameList("a", to: "B") == .failed)
    }
}

@MainActor
@Suite("SpyTodoStore")
struct SpyTodoStoreTests {
    @Test func theHarnessExposesTheSpy() {
        let h = EngineHarness()
        #expect(h.todos.calls.isEmpty)
        #expect(h.todos.access == .allowed)
        #expect(h.engine.todos === h.todos)
    }

    @Test func theSpyRecordsWritesAndFiltersReads() async {
        let spy = SpyTodoStore()
        let since = Date(timeIntervalSince1970: 1_800_000_000)
        spy.todosValue = [
            makeTodo("a", list: "x"),
            makeTodo("b", list: "y"),
            makeTodo("old", list: "x", done: true, doneAt: since.addingTimeInterval(-1)),
            makeTodo("new", list: "x", done: true, doneAt: since)
        ]
        let got = await spy.todos(listIDs: ["x"], completedSince: since)
        #expect(got.map(\.id) == ["a", "new"])
        #expect(spy.readRequests == [["x"]])
        #expect(spy.completedSinceRequests == [since])
        #expect(spy.setDone("a", true) == .done(id: "new"))
        #expect(spy.delete("a") == .done(id: "new"))
        #expect(spy.calls == [.doneSet("a", true), .deleted("a")])
    }
}
