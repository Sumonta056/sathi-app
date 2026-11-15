import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todo add field")
struct TodoAddFieldTests {
    private func field(_ h: EngineHarness, title: String) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(TodoAddField(listID: "inbox", title: title), h).inspect()
    }

    private func button(_ sut: InspectableView<ViewType.ClassifiedView>) throws -> InspectableView<ViewType.Button> {
        try sut.find(viewWithAccessibilityIdentifier: "todos.add.button").find(ViewType.Button.self, relation: .parent)
    }

    @Test func addIsDisabledWhenBlank() async throws {
        let h = await EngineHarness.pageFixture()
        #expect(try button(field(h, title: "  ")).isDisabled())
        #expect(try !button(field(h, title: "Buy milk")).isDisabled())
    }

    @Test func addCallsTheStoreWithTheListAndTheTitle() async throws {
        let h = await EngineHarness.pageFixture()
        try button(field(h, title: "Buy milk")).tap()
        await waitUntil { !h.todos.calls.isEmpty }
        #expect(h.todos.calls == [.added(TodoDraft(listID: "inbox", title: "Buy milk", notes: "", due: nil))])
    }

    @Test func hasATextFieldWithAnIdentifier() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try field(h, title: "")
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.add.field") }
    }
}
