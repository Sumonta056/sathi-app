import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todos polish")
struct TodosPolishTests {
    private func side(_ h: EngineHarness, _ selection: TodoSelection) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(TodoSideColumn(selection: Box(selection).binding), h).inspect()
    }

    private func withEmptyList() async -> EngineHarness {
        let lists = [makeTodoList("inbox", "Inbox"), makeTodoList("work", "Work"), makeTodoList("empty", "Empty")]
        return await EngineHarness.todosReady(lists: lists, items: EngineHarness.pageItems)
    }

    private func withEmptyAccount() async -> EngineHarness {
        let lists = [makeTodoList("inbox", "Inbox"), makeReadOnlyTodoList("ro")]
        return await EngineHarness.todosReady(lists: lists, items: [makeTodo("a", "Alpha", list: "inbox")])
    }

    @Test func aMissingListFallsBackToAll() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodosPage(selection: .list("gone")), h).inspect()
        #expect(try sut.find(TodoItemsColumn.self).actualView().selection == .smart(.all))
    }

    @Test func theSideColumnHidesAListWithNoOpenTodo() async throws {
        let sut = try await side(withEmptyList(), .smart(.all))
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.list.empty")) == nil)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.list.inbox") }
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.list.work") }
    }

    @Test func theSideColumnKeepsTheSelectedEmptyList() async throws {
        let sut = try await side(withEmptyList(), .list("empty"))
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.list.empty") }
    }

    @Test func anAccountWithNoShownListHasNoGroupHeader() async throws {
        let sut = try await side(withEmptyAccount(), .smart(.all))
        #expect(Find.lacks(sut, text: "EXCHANGE"))
        #expect(throws: Never.self) { try sut.find(text: "ICLOUD") }
    }

    @Test func theSelectedEmptyListKeepsItsGroupHeader() async throws {
        let sut = try await side(withEmptyAccount(), .list("ro"))
        #expect(throws: Never.self) { try sut.find(text: "EXCHANGE") }
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.list.ro") }
    }

    @Test func theSectionNameUsesTheCalmTextColorNotTheListColor() {
        #expect(TodoSectionHeader.nameColor == Night.todoSectionName)
        #expect(TodoSectionHeader.nameColor != Night.todoList("#FF3B30"))
    }

    @Test func theSectionRuleIsThePlainDivider() {
        #expect(TodoSectionHeader.ruleColor == Night.divider)
    }

    @Test func theAddFieldIsCompact() {
        #expect(UIMetrics.todoAddHeight <= 36)
    }
}
