import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoListOrder")
struct EngineTodoListOrderTests {
    private func ids(_ lists: [TodoList]) -> [String] { lists.map(\.id) }

    private func ready(_ order: [String] = [], hidden: Set<String> = []) async -> EngineHarness {
        let lists = [makeTodoList("inbox", "Inbox"), makeTodoList("work", "Work"), makeReadOnlyTodoList("ro")]
        return await EngineHarness.todosReady(lists: lists, items: EngineHarness.pageItems) {
            $0.prefs.todos.listOrder = order
            $0.prefs.todos.hiddenListIDs = hidden
        }
    }

    @Test func orderedListsFollowTheSavedOrder() async {
        let h = await ready(["work", "inbox"])
        #expect(ids(h.engine.todoOrderedLists) == ["work", "inbox", "ro"])
    }

    @Test func noSavedOrderKeepsTheStoreOrder() async {
        let h = await ready()
        #expect(ids(h.engine.todoOrderedLists) == ["inbox", "work", "ro"])
    }

    @Test func sideColumnAndAllSectionsAgree() async {
        let h = await ready(["work", "inbox"])
        let side = ids(h.engine.todoSideLists(.smart(.all)))
        let sections = h.engine.todoPage(.smart(.all)).sections.map(\.list.id)
        #expect(side == ["work", "inbox", "ro"])
        #expect(sections == side)
    }

    @Test func theDefaultAddTargetOnAllIsTheFirstWritableOrderedList() async {
        let h = await ready(["work", "inbox"])
        #expect(h.engine.todoPage(.smart(.all)).targetListID == "work")
    }

    @Test func movingAListSavesTheOrder() async {
        let h = await ready()
        h.engine.moveTodoList("work", before: "inbox")
        #expect(h.engine.data.prefs.todos.listOrder.filter { ["inbox", "work"].contains($0) } == ["work", "inbox"])
        #expect(ids(h.engine.todoOrderedLists) == ["work", "inbox", "ro"])
    }

    @Test func movingBeforeNilPutsTheListAtTheEndOfItsAccount() async {
        let h = await ready()
        h.engine.moveTodoList("inbox", before: nil)
        #expect(ids(h.engine.todoOrderedLists) == ["work", "inbox", "ro"])
    }

    @Test func movingToAnotherAccountChangesNothing() async {
        let h = await ready()
        h.engine.moveTodoList("inbox", before: "ro")
        #expect(h.engine.data.prefs.todos.listOrder.isEmpty)
    }

    @Test func anUnknownListChangesNothing() async {
        let h = await ready()
        h.engine.moveTodoList("zzz", before: "inbox")
        #expect(h.engine.data.prefs.todos.listOrder.isEmpty)
    }

    @Test func aHiddenListKeepsItsPlaceAfterADrag() async {
        let lists = [makeTodoList("one"), makeTodoList("hid"), makeTodoList("two"), makeTodoList("three")]
        let items = [makeTodo("t1", "T1", list: "one"), makeTodo("t2", "T2", list: "two"), makeTodo("t3", "T3", list: "three")]
        let h = await EngineHarness.todosReady(lists: lists, items: items) { $0.prefs.todos.hiddenListIDs = ["hid"] }
        h.engine.moveTodoList("three", before: "two")
        let saved = h.engine.data.prefs.todos.listOrder
        #expect(saved == ["one", "hid", "three", "two"])
    }

    @Test func anEmptyListKeepsItsPlaceAfterADrag() async {
        let lists = [makeTodoList("one"), makeTodoList("none"), makeTodoList("two"), makeTodoList("three")]
        let items = [makeTodo("t1", "T1", list: "one"), makeTodo("t2", "T2", list: "two"), makeTodo("t3", "T3", list: "three")]
        let h = await EngineHarness.todosReady(lists: lists, items: items)
        h.engine.moveTodoList("three", before: "two")
        #expect(h.engine.data.prefs.todos.listOrder == ["one", "none", "three", "two"])
    }

    @Test func staleSavedIDsAreRemovedByAMove() async {
        let h = await ready(["gone", "inbox", "work"])
        h.engine.moveTodoList("work", before: "inbox")
        #expect(!h.engine.data.prefs.todos.listOrder.contains("gone"))
    }

    @Test func withoutAccessAMoveKeepsTheSavedOrder() async {
        let h = await EngineHarness.todosReady(access: .denied) { $0.prefs.todos.listOrder = ["gone", "inbox"] }
        h.engine.moveTodoList("inbox", before: nil)
        #expect(h.engine.data.prefs.todos.listOrder == ["gone", "inbox"])
    }
}
