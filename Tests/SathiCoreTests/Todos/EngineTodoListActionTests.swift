import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoListActions")
struct EngineTodoListActionTests {
    private func ready(access: TodoAccess = .allowed) async -> EngineHarness {
        await EngineHarness.todosReady(
            lists: [makeTodoList("inbox", "Inbox"), makeTodoList("work", "Work"), makeReadOnlyTodoList("ro")],
            items: [makeTodo("a", "Alpha", list: "inbox"), makeTodo("r", "Locked", list: "ro")],
            access: access
        )
    }

    @Test func createListCallsTheStoreWithTheTrimmedName() async {
        let h = await ready()
        let color = Limits.todoListColors[3]
        _ = await h.engine.createTodoList(TodoListDraft(name: "  Trips ", colorHex: color, accountID: "icloud"))
        #expect(h.todos.calls == [.listCreated(TodoListDraft(name: "Trips", colorHex: color, accountID: "icloud"))])
    }

    @Test func createListRefusesABlankNameAndAnUnknownColor() async {
        let h = await ready()
        _ = await h.engine.createTodoList(TodoListDraft(name: " ", colorHex: Limits.todoListColors[0], accountID: "icloud"))
        _ = await h.engine.createTodoList(TodoListDraft(name: "Trips", colorHex: "#123456", accountID: "icloud"))
        #expect(h.todos.calls.isEmpty)
    }

    @Test func renameListCallsTheStoreWithTheTrimmedName() async {
        let h = await ready()
        _ = await h.engine.renameTodoList("inbox", to: "  Home ")
        #expect(h.todos.calls == [.listRenamed("inbox", "Home")])
    }

    @Test func renameRefusesABlankNameAndAReadOnlyList() async {
        let h = await ready()
        _ = await h.engine.renameTodoList("inbox", to: "  ")
        _ = await h.engine.renameTodoList("ro", to: "Mine")
        #expect(h.todos.calls.isEmpty)
    }

    @Test func aFailedWriteReturnsTheFailure() async {
        let h = await ready()
        h.todos.nextResult = .failed
        let r = await h.engine.setTodoDone("a", true)
        #expect(r == .failed)
    }

    @Test func nothingIsWrittenWhenAccessIsDenied() async {
        let h = await ready(access: .denied)
        let results = await [
            h.engine.addTodo(TodoDraft(listID: "inbox", title: "X", notes: "", due: nil)),
            h.engine.editTodo("a", TodoEdit(title: "X", notes: "", due: nil)),
            h.engine.setTodoDone("a", true),
            h.engine.moveTodo("a", to: "work"),
            h.engine.deleteTodo("a"),
            h.engine.createTodoList(TodoListDraft(name: "N", colorHex: Limits.todoListColors[0], accountID: "icloud")),
            h.engine.renameTodoList("inbox", to: "N")
        ]
        #expect(results.allSatisfy { $0 == .failed })
        #expect(h.todos.calls.isEmpty)
    }

    @Test func nothingIsWrittenWhenTodosIsOff() async {
        let h = await EngineHarness.todosReady(items: [makeTodo("a")], on: false)
        _ = await h.engine.setTodoDone("a", true)
        _ = await h.engine.addTodo(TodoDraft(listID: "inbox", title: "X", notes: "", due: nil))
        #expect(h.todos.calls.isEmpty)
    }

    @Test func defaultAccountFollowsThePreferredThenTheRule() async {
        let h = await ready()
        h.todos.accountsValue = [
            TodoAccount(id: "ex", name: "Exchange", allowsNewLists: true),
            TodoAccount(id: "ic", name: "iCloud", allowsNewLists: true, isICloud: true)
        ]
        #expect(h.engine.todoDefaultAccountID == "ic")
        h.engine.data.prefs.todos.newListAccountID = "ex"
        #expect(h.engine.todoDefaultAccountID == "ex")
    }
}
