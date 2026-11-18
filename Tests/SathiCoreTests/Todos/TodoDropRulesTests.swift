import SathiCore
import SathiTestSupport
import Testing

@Suite("TodoDropRules")
struct TodoDropRulesTests {
    private let ids = ["a", "b", "c", "d"]

    @Test func movedPutsTheTodoAtItsNewPlace() {
        #expect(TodoRules.moved(ids, id: "a", before: "d") == ["b", "c", "a", "d"])
        #expect(TodoRules.moved(ids, id: "a", before: nil) == ["b", "c", "d", "a"])
        #expect(TodoRules.moved(ids, id: "x", before: nil) == nil)
        #expect(TodoRules.moved(ids, id: "a", before: "x") == nil)
    }
}

@Suite("TodoOrderEdges")
struct TodoOrderEdgesTests {
    @Test func aRepeatedIDInTheOrderShowsTheTodoOnce() {
        let todos = [makeTodo("a", "A", list: "l"), makeTodo("b", "B", list: "l")]
        #expect(TodoRules.ordered(todos, order: ["b", "a", "b"]).map(\.id) == ["b", "a"])
    }

    @Test func prunedKeepsOnlyKnownLists() {
        let order = ["a": ["1"], "gone": ["2"]]
        #expect(TodoRules.pruned(order, listIDs: ["a", "b"]) == ["a": ["1"]])
        #expect(TodoRules.pruned(order, listIDs: []) == order)
    }
}
