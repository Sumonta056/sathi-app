import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("TodoListOrder")
struct TodoListOrderTests {
    private let a = makeTodoList("a", "A")
    private let b = makeTodoList("b", "B")
    private let c = makeTodoList("c", "C")
    private let x = makeTodoList("x", "X", account: "work")
    private let y = makeTodoList("y", "Y", account: "work")

    private func ids(_ lists: [TodoList]) -> [String] { lists.map(\.id) }

    @Test func savedOrderWins() {
        #expect(ids(TodoListOrder.ordered([a, b, c], order: ["c", "a", "b"])) == ["c", "a", "b"])
    }

    @Test func noSavedOrderKeepsStoreOrder() {
        #expect(ids(TodoListOrder.ordered([a, b, c], order: [])) == ["a", "b", "c"])
    }

    @Test func aNewListGoesToTheEndOfItsGroup() {
        #expect(ids(TodoListOrder.ordered([a, b, c, x], order: ["c", "a"])) == ["c", "a", "b", "x"])
    }

    @Test func unknownSavedIDsAreIgnored() {
        #expect(ids(TodoListOrder.ordered([a, b], order: ["zzz", "b", "a"])) == ["b", "a"])
    }

    @Test func orderAppliesInsideEachAccountGroup() {
        let out = TodoListOrder.ordered([a, x, b, y], order: ["y", "b", "x", "a"])
        #expect(ids(out) == ["b", "a", "y", "x"])
    }

    @Test func groupOrderStaysWhenTheFirstSavedIDIsInTheSecondAccount() {
        let out = TodoListOrder.ordered([a, b, x, y], order: ["x", "a"])
        #expect(ids(out) == ["a", "b", "x", "y"])
    }

    @Test func orderedOfNothingIsNothing() {
        #expect(TodoListOrder.ordered([], order: ["a"]).isEmpty)
    }

    @Test func movingInsideOneAccountPutsTheListBeforeThePeer() {
        let out = TodoListOrder.moved(all: [a, b, c], order: [], id: "c", before: "a")
        #expect(out?.filter { ["a", "b", "c"].contains($0) } == ["c", "a", "b"])
    }

    @Test func movingBeforeNilPutsTheListAtTheEndOfItsGroup() {
        let out = TodoListOrder.moved(all: [a, b, c, x], order: [], id: "a", before: nil)
        #expect(out?.filter { ["a", "b", "c"].contains($0) } == ["b", "c", "a"])
    }

    @Test func aMoveStartsFromTheSavedOrder() {
        let out = TodoListOrder.moved(all: [a, b, c], order: ["c", "a", "b"], id: "b", before: "a")
        #expect(out?.filter { ["a", "b", "c"].contains($0) } == ["c", "b", "a"])
    }

    @Test func movingToAnotherAccountChangesNothing() {
        #expect(TodoListOrder.moved(all: [a, b, x, y], order: [], id: "a", before: "x") == nil)
    }

    @Test func movingBeforeItselfChangesNothing() {
        #expect(TodoListOrder.moved(all: [a, b], order: [], id: "a", before: "a") == nil)
    }

    @Test func anUnknownListChangesNothing() {
        #expect(TodoListOrder.moved(all: [a, b], order: [], id: "zzz", before: "a") == nil)
    }

    @Test func listsBetweenTheMovedOnesKeepTheirPlace() {
        let out = TodoListOrder.moved(all: [a, b, c], order: [], id: "a", before: "c")
        #expect(out?.filter { ["a", "b", "c"].contains($0) } == ["b", "a", "c"])
    }

    @Test func theResultCanBeAppliedBack() throws {
        let all = [a, b, c, x]
        let saved = try #require(TodoListOrder.moved(all: all, order: [], id: "c", before: "a"))
        #expect(ids(TodoListOrder.ordered(all, order: saved)) == ["c", "a", "b", "x"])
    }

    @Test func staleIDsAreDroppedAgainstTheFullSet() throws {
        let out = try #require(TodoListOrder.moved(all: [a, b], order: ["gone", "a", "b"], id: "b", before: "a"))
        #expect(!out.contains("gone"))
    }

    @Test func anEmptySetDoesNotPrune() {
        #expect(TodoListOrder.moved(all: [], order: ["gone"], id: "gone", before: nil) == nil)
    }
}
