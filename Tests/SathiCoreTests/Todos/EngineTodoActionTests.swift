import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoActions")
struct EngineTodoActionTests {
    private func ready(access: TodoAccess = .allowed) async -> EngineHarness {
        await EngineHarness.todosReady(
            lists: [makeTodoList("inbox", "Inbox"), makeTodoList("work", "Work"), makeReadOnlyTodoList("ro")],
            items: [makeTodo("a", "Alpha", list: "inbox"), makeTodo("r", "Locked", list: "ro")],
            access: access
        )
    }

    private let due = TodoDue(date: day(2026, 3, 5, 9), hasTime: true)

    @Test func addCallsTheStoreWithTheTrimmedTitle() async {
        let h = await ready()
        let r = await h.engine.addTodo(TodoDraft(listID: "inbox", title: "  Buy milk  ", notes: "2 l", due: due))
        #expect(r == .done(id: "new"))
        #expect(h.todos.calls == [.added(TodoDraft(listID: "inbox", title: "Buy milk", notes: "2 l", due: due))])
    }

    @Test func addWithABlankTitleWritesNothing() async {
        let h = await ready()
        let r = await h.engine.addTodo(TodoDraft(listID: "inbox", title: "   ", notes: "", due: nil))
        #expect(r == .failed)
        #expect(h.todos.calls.isEmpty)
    }

    @Test func addToAReadOnlyListWritesNothing() async {
        let h = await ready()
        let r = await h.engine.addTodo(TodoDraft(listID: "ro", title: "X", notes: "", due: nil))
        #expect(r == .failed)
        #expect(h.todos.calls.isEmpty)
    }

    @Test func addRefreshesTheSnapshot() async {
        let h = await ready()
        h.todos.todosValue.append(makeTodo("n", "New", list: "inbox"))
        let reads = h.todos.readRequests.count
        _ = await h.engine.addTodo(TodoDraft(listID: "inbox", title: "New", notes: "", due: nil))
        #expect(h.todos.readRequests.count == reads + 1)
        #expect(Set(h.engine.todoSnapshot.open.map(\.id)) == ["a", "r", "n"])
    }

    @Test func editCallsTheStore() async {
        let h = await ready()
        let edit = TodoEdit(title: "Alpha 2", notes: "n", due: due)
        _ = await h.engine.editTodo("a", edit)
        #expect(h.todos.calls == [.updated("a", edit)])
    }

    @Test func editOfAReadOnlyListTodoWritesNothing() async {
        let h = await ready()
        let r = await h.engine.editTodo("r", TodoEdit(title: "X", notes: "", due: nil))
        #expect(r == .failed)
        #expect(h.todos.calls.isEmpty)
    }

    @Test func editWithABlankTitleWritesNothing() async {
        let h = await ready()
        _ = await h.engine.editTodo("a", TodoEdit(title: " ", notes: "", due: nil))
        #expect(h.todos.calls.isEmpty)
    }

    @Test(arguments: [true, false])
    func doneCallsTheStoreWithTheValue(_ done: Bool) async {
        let h = await ready()
        _ = await h.engine.setTodoDone("a", done)
        #expect(h.todos.calls == [.doneSet("a", done)])
    }

    @Test func doneOfAReadOnlyListTodoWritesNothing() async {
        let h = await ready()
        _ = await h.engine.setTodoDone("r", true)
        #expect(h.todos.calls.isEmpty)
    }

    @Test func doneRefreshesTheSnapshot() async {
        let h = await ready()
        h.todos.todosValue[0] = makeTodo("a", "Alpha", list: "inbox", done: true, doneAt: day(2026, 3, 4, 10))
        _ = await h.engine.setTodoDone("a", true)
        #expect(!h.engine.todoSnapshot.open.contains { $0.id == "a" })
        #expect(h.engine.todoSnapshot.recentCompleted.map(\.id) == ["a"])
    }

    @Test func moveCallsTheStore() async {
        let h = await ready()
        _ = await h.engine.moveTodo("a", to: "work")
        #expect(h.todos.calls == [.moved("a", "work")])
    }

    @Test func moveToAReadOnlyListWritesNothing() async {
        let h = await ready()
        _ = await h.engine.moveTodo("a", to: "ro")
        #expect(h.todos.calls.isEmpty)
    }

    @Test func deleteCallsTheStore() async {
        let h = await ready()
        _ = await h.engine.deleteTodo("a")
        #expect(h.todos.calls == [.deleted("a")])
    }

    @Test func deleteOfAReadOnlyListTodoWritesNothing() async {
        let h = await ready()
        _ = await h.engine.deleteTodo("r")
        #expect(h.todos.calls.isEmpty)
    }

    @Test func saveWithANewListUpdatesThenMoves() async throws {
        let h = await ready()
        let todo = try #require(h.engine.todoSnapshot.open.first { $0.id == "a" })
        var form = TodoEditForm(todo: todo, calendar: .current)
        form.title = "Alpha 2"
        form.listID = "work"
        _ = await h.engine.saveTodo(todo, form)
        #expect(h.todos.calls == [
            .updated("a", form.edit(calendar: .current)),
            .moved("a", "work")
        ])
    }

    @Test func saveWithTheSameListOnlyUpdates() async throws {
        let h = await ready()
        let todo = try #require(h.engine.todoSnapshot.open.first { $0.id == "a" })
        var form = TodoEditForm(todo: todo, calendar: .current)
        form.notes = "changed"
        _ = await h.engine.saveTodo(todo, form)
        #expect(h.todos.calls == [.updated("a", form.edit(calendar: .current))])
    }
}
