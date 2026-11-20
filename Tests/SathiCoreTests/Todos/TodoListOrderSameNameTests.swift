import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("TodoListOrderSameName")
struct TodoListOrderSameNameTests {
    private func list(_ id: String, account: String) -> TodoList {
        TodoList(id: id, name: id.uppercased(), colorHex: "#FF3B30", accountID: account, accountName: "Work", canEdit: true)
    }

    private var lists: [TodoList] {
        [list("a1", account: "acc1"), list("b1", account: "acc2"), list("a2", account: "acc1"), list("b2", account: "acc2")]
    }

    @Test func accountsWithOneNameStayApart() {
        let out = TodoListOrder.ordered(lists, order: [])
        #expect(out.map(\.id) == ["a1", "a2", "b1", "b2"])
    }

    @Test func aMoveInsideOneOfThemWorks() {
        let out = TodoListOrder.moved(all: lists, order: [], id: "a2", before: "a1")
        #expect(out == ["a2", "a1", "b1", "b2"])
    }

    @Test func aMoveToTheOtherAccountWithTheSameNameDoesNothing() {
        #expect(TodoListOrder.moved(all: lists, order: [], id: "a1", before: "b1") == nil)
    }

    @Test func theEngineKeepsThemApartInSideAndSections() async {
        let items = lists.enumerated().map { makeTodo("t\($0.offset)", "T", list: $0.element.id) }
        let h = await EngineHarness.todosReady(lists: lists, items: items)
        let expected = ["a1", "a2", "b1", "b2"]
        #expect(h.engine.todoSideLists(.smart(.all)).map(\.id) == expected)
        #expect(h.engine.todoPage(.smart(.all)).sections.map(\.list.id) == expected)
        h.engine.moveTodoList("a2", before: "a1")
        #expect(h.engine.todoOrderedLists.map(\.id) == ["a2", "a1", "b1", "b2"])
    }
}
