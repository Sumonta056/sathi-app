import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todo add layout")
struct TodoAddLayoutTests {
    private func row(_ sut: InspectableView<some BaseViewType>, of id: String) throws -> InspectableView<ViewType.HStack> {
        try sut.find(viewWithAccessibilityIdentifier: id).find(ViewType.HStack.self, relation: .parent)
    }

    @Test func theAddButtonStaysOnTheTextFieldRow() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodoAddField(listID: "inbox", title: "Call"), h).inspect()
        let fieldRow = try row(sut, of: "todos.add.field")
        #expect(throws: Never.self) { try fieldRow.find(viewWithAccessibilityIdentifier: "todos.add.button") }
    }

    @Test func theDueChipSitsOnTheFieldRow() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodoAddField(listID: "inbox", title: "Call"), h).inspect()
        let fieldRow = try row(sut, of: "todos.add.field")
        #expect(throws: Never.self) { try fieldRow.find(viewWithAccessibilityIdentifier: "todos.add.due") }
        #expect(throws: Never.self) { try fieldRow.find(viewWithAccessibilityIdentifier: "todos.add.button") }
    }

    @Test func theDuePopoverHasAFixedWidthThatFitsTheNarrowestPage() {
        let narrowest = UIMetrics.mainWindowMinSize.width - UIMetrics.sidebarRailWidth - UIMetrics.todoSideWidthNarrow
        #expect(UIMetrics.todoDuePopoverWidth <= narrowest)
        #expect(UIMetrics.todoDuePopoverWidth >= UIMetrics.todoDueContentWidth + 2 * UIMetrics.todoEditPadding)
    }

    @Test func theDueControlPutsTheDateAndTimeUnderTheSwitch() async throws {
        let h = await EngineHarness.pageFixture()
        let view = TodoEditDue(hasDate: .constant(true), date: .constant(day(2026, 3, 6)), minutes: .constant(540))
        let sut = try hosted(view, h).inspect()
        let switchRow = try row(sut, of: "todos.edit.hasDate")
        #expect((try? switchRow.find(viewWithAccessibilityIdentifier: "todos.edit.date")) == nil)
        #expect((try? switchRow.find(viewWithAccessibilityIdentifier: "todos.edit.noTime")) == nil)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.edit.noTime") }
        #expect(throws: Never.self) { try sut.find(TimeMenu.self) }
    }
}
