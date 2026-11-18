import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoOrderPrune")
struct EngineTodoOrderPruneTests {
    @Test func aMoveDropsTheOrderOfListsThatAreGone() async {
        let lists = [makeTodoList("inbox", "Inbox"), makeTodoList("work", "Work")]
        let h = await EngineHarness.todosReady(lists: lists, items: EngineHarness.pageItems) {
            $0.prefs.todos.order = ["gone": ["x"], "work": ["d", "b"]]
        }
        h.engine.moveTodo("c", before: "f")
        #expect(h.engine.data.prefs.todos.order == ["inbox": ["c", "f", "a"], "work": ["d", "b"]])
    }

    @Test func aMoveKeepsTheOrderOfAHiddenList() async {
        let lists = [makeTodoList("inbox", "Inbox"), makeTodoList("work", "Work")]
        let h = await EngineHarness.todosReady(lists: lists, items: EngineHarness.pageItems) {
            $0.prefs.todos.order = ["work": ["d", "b"]]
            $0.prefs.todos.hiddenListIDs = ["work"]
        }
        h.engine.moveTodo("c", before: "f")
        #expect(h.engine.data.prefs.todos.order["work"] == ["d", "b"])
    }
}
