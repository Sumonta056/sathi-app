import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoOrder")
struct EngineTodoOrderTests {
    private func ids(_ items: [Todo]) -> [String] { items.map(\.id) }

    private func ordered(_ order: [String: [String]]) async -> EngineHarness {
        let lists = [makeTodoList("inbox", "Inbox"), makeTodoList("work", "Work"), makeReadOnlyTodoList("ro")]
        return await EngineHarness.todosReady(lists: lists, items: EngineHarness.pageItems) { $0.prefs.todos.order = order }
    }

    @Test func movingBeforeAnotherTodoSavesTheWholeListOrder() async {
        let h = await EngineHarness.pageFixture()
        h.engine.moveTodo("c", before: "f")
        #expect(h.engine.data.prefs.todos.order == ["inbox": ["c", "f", "a"]])
        #expect(ids(h.engine.todoPage(.list("inbox")).open) == ["c", "f", "a"])
    }

    @Test func movingBeforeNilPutsTheTodoAtTheEnd() async {
        let h = await EngineHarness.pageFixture()
        h.engine.moveTodo("f", before: nil)
        #expect(h.engine.data.prefs.todos.order["inbox"] == ["a", "c", "f"])
    }

    @Test func aMoveStartsFromTheShownOrder() async {
        let h = await ordered(["inbox": ["c", "a", "f"]])
        h.engine.moveTodo("f", before: "a")
        #expect(h.engine.data.prefs.todos.order["inbox"] == ["c", "f", "a"])
    }

    @Test func aMoveOnlyChangesItsOwnList() async {
        let h = await ordered(["work": ["d", "b"]])
        h.engine.moveTodo("c", before: "f")
        #expect(h.engine.data.prefs.todos.order == ["inbox": ["c", "f", "a"], "work": ["d", "b"]])
    }

    @Test func movingBeforeItselfChangesNothing() async {
        let h = await EngineHarness.pageFixture()
        h.engine.moveTodo("a", before: "a")
        #expect(h.engine.data.prefs.todos.order.isEmpty)
    }

    @Test func anUnknownTodoChangesNothing() async {
        let h = await EngineHarness.pageFixture()
        h.engine.moveTodo("zzz", before: "a")
        #expect(h.engine.data.prefs.todos.order.isEmpty)
    }

    @Test func movingBeforeATodoOfAnotherListChangesNothing() async {
        let h = await EngineHarness.pageFixture()
        h.engine.moveTodo("a", before: "b")
        #expect(h.engine.data.prefs.todos.order.isEmpty)
        #expect(ids(h.engine.todoPage(.list("inbox")).open) == ["f", "a", "c"])
    }

    @Test func aMoveDropsIDsThatAreNoLongerOpenInTheList() async {
        let h = await ordered(["inbox": ["gone", "c", "g"]])
        h.engine.moveTodo("a", before: "f")
        #expect(h.engine.data.prefs.todos.order["inbox"] == ["a", "f", "c"])
    }

    @Test func aListPageFollowsTheSavedOrderWithNewTodosFirst() async {
        let h = await ordered(["inbox": ["a", "f"]])
        #expect(ids(h.engine.todoPage(.list("inbox")).open) == ["c", "a", "f"])
    }

    @Test func allSectionsFollowTheSavedOrder() async {
        let h = await ordered(["inbox": ["c", "a", "f"], "work": ["d", "b"]])
        let sections = h.engine.todoPage(.smart(.all)).sections
        #expect(sections.map { ids($0.todos) } == [["c", "a", "f"], ["d", "b"], ["e"]])
    }

    @Test func aMoveShowsInTheAllSection() async {
        let h = await EngineHarness.pageFixture()
        h.engine.moveTodo("d", before: "b")
        #expect(h.engine.todoPage(.smart(.all)).sections.map { ids($0.todos) } == [["f", "a", "c"], ["d", "b"], ["e"]])
    }

    @Test func todayIgnoresTheSavedOrder() async {
        let h = await ordered(["inbox": ["a", "f"], "work": ["b"]])
        #expect(ids(h.engine.todoPage(.smart(.today)).open) == ["f", "a", "b"])
    }

    @Test func scheduledIgnoresTheSavedOrder() async {
        let h = await ordered(["inbox": ["a", "f"], "work": ["d", "b"]])
        #expect(ids(h.engine.todoPage(.smart(.scheduled)).open) == ["f", "a", "b", "d"])
    }

    @Test func sideListsHideAnEmptyListUnlessItIsSelected() async {
        let lists = [makeTodoList("inbox", "Inbox"), makeTodoList("work", "Work"), makeReadOnlyTodoList("ro"), makeTodoList("empty", "Empty")]
        let h = await EngineHarness.todosReady(lists: lists, items: EngineHarness.pageItems)
        #expect(h.engine.todoSideLists(.smart(.all)).map(\.id) == ["inbox", "work", "ro"])
        #expect(h.engine.todoSideLists(.list("empty")).map(\.id) == ["inbox", "work", "empty", "ro"])
    }
}
