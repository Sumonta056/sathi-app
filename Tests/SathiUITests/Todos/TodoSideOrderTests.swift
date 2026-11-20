import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todos side order")
struct TodoSideOrderTests {
    private func names(_ h: EngineHarness) throws -> [String] {
        let sut = try hosted(TodoSideColumn(selection: Box(TodoSelection.smart(.all)).binding), h).inspect()
        let shown: Set<String> = ["Inbox", "Work", "Shared"]
        return try sut.findAll(ViewType.Text.self).compactMap { try? $0.string() }.filter { shown.contains($0) }
    }

    private func ready(_ order: [String]) async -> EngineHarness {
        let lists = [makeTodoList("inbox", "Inbox"), makeTodoList("work", "Work"), makeReadOnlyTodoList("ro")]
        return await EngineHarness.todosReady(lists: lists, items: EngineHarness.pageItems) { $0.prefs.todos.listOrder = order }
    }

    @Test func sideRowsFollowTheSavedOrder() async throws {
        let h = await ready(["work", "inbox"])
        #expect(try names(h) == ["Work", "Inbox", "Shared"])
    }

    @Test func sideRowsKeepStoreOrderWithoutASavedOrder() async throws {
        let h = await ready([])
        #expect(try names(h) == ["Inbox", "Work", "Shared"])
    }

    @Test func aMoveReordersTheSideRows() async throws {
        let h = await ready([])
        h.engine.moveTodoList("work", before: "inbox")
        #expect(try names(h) == ["Work", "Inbox", "Shared"])
    }

    @Test func aClickOnARowStillSelectsIt() async throws {
        let h = await ready(["work", "inbox"])
        let box = Box(TodoSelection.smart(.all))
        let sut = try hosted(TodoSideColumn(selection: box.binding), h).inspect()
        try sut.find(viewWithAccessibilityIdentifier: "todos.list.inbox").find(ViewType.Button.self, relation: .parent).tap()
        #expect(box.value == .list("inbox"))
    }
}
