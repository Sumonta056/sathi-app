import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todo row layout")
struct TodoRowLayoutTests {
    private func row(_ h: EngineHarness, _ todo: Todo) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(TodoRow(todo: todo, canEdit: true, onSelect: {}), h).inspect()
    }

    private func dueTodo() -> Todo {
        var todo = makeTodo("a", "Buy milk", due: TodoDue(date: day(2026, 3, 4, 14, 30), hasTime: true))
        todo.repeats = true
        return todo
    }

    @Test func theTitleHasItsIdentifier() async throws {
        let h = await EngineHarness.pageFixture()
        let title = try row(h, makeTodo("a", "Buy milk")).find(viewWithAccessibilityIdentifier: "todos.row.title.a")
        #expect(throws: Never.self) { try title.find(text: "Buy milk") }
    }

    @Test func theMetaHoldsTheDueTextAndTheRepeatsLabel() async throws {
        let h = await EngineHarness.pageFixture()
        let meta = try row(h, dueTodo()).find(viewWithAccessibilityIdentifier: "todos.row.meta.a")
        #expect(throws: Never.self) { try meta.find(viewWithAccessibilityIdentifier: "todos.row.due.a") }
        #expect(throws: Never.self) { try meta.find(text: Copywriter.todoRepeats) }
    }

    @Test func theMetaSitsOnTheTitleRow() async throws {
        let h = await EngineHarness.pageFixture()
        let meta = try row(h, dueTodo()).find(viewWithAccessibilityIdentifier: "todos.row.meta.a")
        let titleRow = try meta.find(ViewType.HStack.self, relation: .parent)
        #expect(throws: Never.self) { try titleRow.find(viewWithAccessibilityIdentifier: "todos.row.title.a") }
    }

    @Test func theMetaIsNotInAStackUnderTheTitle() async throws {
        let h = await EngineHarness.pageFixture()
        let meta = try row(h, dueTodo()).find(viewWithAccessibilityIdentifier: "todos.row.meta.a")
        let column = try? meta.find(ViewType.VStack.self, relation: .parent)
        #expect((try? column?.find(viewWithAccessibilityIdentifier: "todos.row.title.a")) == nil)
    }
}
