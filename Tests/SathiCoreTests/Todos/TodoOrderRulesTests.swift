import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("TodoOrderRules")
struct TodoOrderRulesTests {
    private let items = ["1", "2", "3", "4"].map { makeTodo($0, list: "a") }

    private func ids(_ todos: [Todo]) -> [String] { todos.map(\.id) }

    private func list(_ id: String, account: String) -> TodoList {
        TodoList(id: id, name: id.uppercased(), colorHex: "#FF3B30", accountID: account, accountName: account, canEdit: true)
    }

    @Test func anEmptyOrderKeepsTheGivenOrder() {
        #expect(ids(TodoRules.ordered(items, order: [])) == ["1", "2", "3", "4"])
    }

    @Test func todosNotInTheOrderComeFirstThenTheSavedOnes() {
        #expect(ids(TodoRules.ordered(items, order: ["3", "1"])) == ["2", "4", "3", "1"])
    }

    @Test func aFullOrderWins() {
        #expect(ids(TodoRules.ordered(items, order: ["4", "2", "1", "3"])) == ["4", "2", "1", "3"])
    }

    @Test func idsThatAreNotInTheListAreIgnored() {
        #expect(ids(TodoRules.ordered(items, order: ["x", "2", "y"])) == ["1", "3", "4", "2"])
    }

    @Test func noTodosGiveNoTodos() {
        #expect(TodoRules.ordered([], order: ["1"]).isEmpty)
    }

    @Test func sideListsKeepOnlyListsWithAnOpenTodo() {
        let lists = [list("a", account: "iCloud"), list("b", account: "iCloud"), list("c", account: "iCloud")]
        let open = [makeTodo("1", list: "c"), makeTodo("2", list: "a")]
        #expect(TodoRules.sideLists(lists, open: open, selected: .smart(.all)).map(\.id) == ["a", "c"])
    }

    @Test func sideListsKeepTheSelectedEmptyList() {
        let lists = [list("a", account: "iCloud"), list("b", account: "iCloud"), list("c", account: "iCloud")]
        let open = [makeTodo("1", list: "c")]
        #expect(TodoRules.sideLists(lists, open: open, selected: .list("b")).map(\.id) == ["b", "c"])
    }

    @Test(arguments: [TodoSmartList.today, .scheduled, .all, .completed])
    func aSmartSelectionKeepsNoEmptyList(_ smart: TodoSmartList) {
        let lists = [list("a", account: "iCloud"), list("b", account: "iCloud")]
        #expect(TodoRules.sideLists(lists, open: [], selected: .smart(smart)).isEmpty)
    }

    @Test func sideListsFollowTheSideOrder() {
        let lists = [list("a", account: "iCloud"), list("x", account: "Work"), list("b", account: "iCloud")]
        let open = [makeTodo("1", list: "x"), makeTodo("2", list: "b"), makeTodo("3", list: "a")]
        #expect(TodoRules.sideLists(lists, open: open, selected: .smart(.all)).map(\.id) == ["a", "b", "x"])
    }

    @Test func doneTodosDoNotKeepAList() {
        let lists = [list("a", account: "iCloud")]
        let open = [makeTodo("1", list: "a", done: true)]
        #expect(TodoRules.sideLists(lists, open: open, selected: .smart(.all)).isEmpty)
    }
}

@Suite("TodoPrefs order")
struct TodoPrefsOrderTests {
    private func prefs(_ json: String) throws -> Prefs {
        try JSONDecoder().decode(Prefs.self, from: Data(json.utf8))
    }

    @Test func theDefaultOrderIsEmpty() {
        #expect(TodoPrefs().order.isEmpty)
    }

    @Test func oldTodosPrefsWithoutAnOrderLoadAnEmptyOrder() throws {
        let p = try prefs(#"{"todos":{"isOn":true,"hiddenListIDs":["a"]}}"#)
        #expect(p.todos.order.isEmpty)
        #expect(p.todos.isOn)
        #expect(p.todos.hiddenListIDs == ["a"])
    }

    @Test func aBadOrderValueFallsBackAndKeepsTheOtherFields() throws {
        let p = try prefs(#"{"todos":{"isOn":true,"order":"oops","askWhenDue":false}}"#)
        #expect(p.todos.order.isEmpty)
        #expect(p.todos.isOn)
        #expect(!p.todos.askWhenDue)
    }

    @Test func aSavedOrderLoads() throws {
        let p = try prefs(#"{"todos":{"order":{"inbox":["c","a"],"work":["b"]}}}"#)
        #expect(p.todos.order == ["inbox": ["c", "a"], "work": ["b"]])
    }

    @Test func theOrderRoundTrips() throws {
        var p = Prefs()
        p.todos.order = ["inbox": ["c", "f", "a"]]
        let back = try JSONDecoder().decode(Prefs.self, from: JSONEncoder().encode(p))
        #expect(back.todos.order == ["inbox": ["c", "f", "a"]])
        #expect(back.todos == p.todos)
    }
}
