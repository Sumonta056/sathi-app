import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todos lists column hide")
struct TodoSidebarHideTests {
    @Test func theSideColumnShowsByDefault() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodosPage(), h).inspect()
        #expect(throws: Never.self) { try sut.find(TodoSideColumn.self) }
    }

    @Test func theSideColumnIsAbsentWhenHidden() async throws {
        let h = await EngineHarness.pageFixture()
        h.engine.setTodoSideHidden(true)
        let sut = try hosted(TodosPage(), h).inspect()
        #expect((try? sut.find(TodoSideColumn.self)) == nil)
        #expect(throws: Never.self) { try sut.find(TodoItemsColumn.self) }
    }

    @Test func theListsButtonOffersToHideWhenShown() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodosPage(), h).inspect()
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.lists.toggle") }
        #expect(throws: Never.self) { try Find.button(sut, label: "Hide lists") }
        #expect((try? Find.button(sut, label: "Show lists")) == nil)
    }

    @Test func theListsButtonOffersToShowWhenHidden() async throws {
        let h = await EngineHarness.pageFixture()
        h.engine.setTodoSideHidden(true)
        let sut = try hosted(TodosPage(), h).inspect()
        #expect(throws: Never.self) { try Find.button(sut, label: "Show lists") }
        #expect((try? Find.button(sut, label: "Hide lists")) == nil)
    }

    @Test func tappingTheButtonHidesTheLists() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodosPage(), h).inspect()
        try Find.button(sut, label: "Hide lists").tap()
        #expect(h.engine.data.prefs.todos.sideHidden)
    }

    @Test func tappingTheButtonShowsTheListsAgain() async throws {
        let h = await EngineHarness.pageFixture()
        h.engine.setTodoSideHidden(true)
        let sut = try hosted(TodosPage(), h).inspect()
        try Find.button(sut, label: "Show lists").tap()
        #expect(!h.engine.data.prefs.todos.sideHidden)
    }

    @Test(arguments: [TodoSelection.smart(.all), .smart(.today), .list("inbox")])
    func theButtonSitsInEveryItemsHeader(_ selection: TodoSelection) async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodoItemsColumn(selection: selection), h).inspect()
        let header = try sut.find(viewWithAccessibilityIdentifier: "todos.header")
        #expect(throws: Never.self) { try header.find(viewWithAccessibilityIdentifier: "todos.lists.toggle") }
    }

    @Test func hidingTheListsKeepsTheBoardOnAll() async throws {
        let h = await EngineHarness.pageFixture(allView: .board)
        h.engine.setTodoSideHidden(true)
        let sut = try hosted(TodosPage(), h).inspect()
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.board") }
    }
}
