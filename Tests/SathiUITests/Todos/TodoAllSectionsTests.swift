import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todo All sections")
struct TodoAllSectionsTests {
    @Test func allShowsAHeaderForEachListWithOpenTodos() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodoItemsColumn(selection: .smart(.all)), h).inspect()
        for id in ["inbox", "work", "ro"] {
            #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.section." + id) }
        }
        let header = try sut.find(viewWithAccessibilityIdentifier: "todos.section.work")
        #expect(throws: Never.self) { try header.find(text: "Work") }
        #expect(throws: Never.self) { try header.find(viewWithAccessibilityIdentifier: "todos.section.dot.work") }
    }

    @Test func allStillShowsEveryOpenTodo() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodoItemsColumn(selection: .smart(.all)), h).inspect()
        for title in ["Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot"] {
            #expect(throws: Never.self) { try sut.find(text: title) }
        }
    }

    @Test(arguments: [TodoSelection.smart(.today), .smart(.scheduled), .list("inbox")])
    func otherPagesShowNoSectionHeaders(_ selection: TodoSelection) async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodoItemsColumn(selection: selection), h).inspect()
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.section.inbox")) == nil)
    }

    @Test func theSideColumnKeepsTheOrderItIsGiven() {
        let a = makeTodoList("a", "A")
        let x = makeTodoList("x", "X", account: "work")
        let b = makeTodoList("b", "B")
        let groups = TodoSideColumn.groups([b, a, x])
        #expect(groups.map(\.name) == ["iCloud", "work"])
        #expect(groups.flatMap(\.lists).map(\.id) == ["b", "a", "x"])
    }

    @Test func theSideColumnListsMatchTheAllSectionsOrder() async {
        let lists = [makeTodoList("inbox", "Inbox"), makeTodoList("work", "Work"), makeReadOnlyTodoList("ro")]
        let h = await EngineHarness.todosReady(lists: lists, items: EngineHarness.pageItems) { $0.prefs.todos.listOrder = ["work", "inbox"] }
        let groups = TodoSideColumn.groups(h.engine.todoSideLists(.smart(.all)))
        #expect(groups.flatMap(\.lists).map(\.id) == h.engine.todoPage(.smart(.all)).sections.map(\.list.id))
    }
}
