import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todo add due")
struct TodoAddDueTests {
    private func button(_ sut: InspectableView<ViewType.ClassifiedView>) throws -> InspectableView<ViewType.Button> {
        try sut.find(viewWithAccessibilityIdentifier: "todos.add.button").find(ViewType.Button.self, relation: .parent)
    }

    @Test func anAddWithAPickedDueWritesIt() async throws {
        let h = await EngineHarness.pageFixture()
        let due = TodoDue(date: day(2026, 3, 6, 15, 30), hasTime: true)
        let sut = try hosted(TodoAddField(listID: "inbox", title: "Call", due: due), h).inspect()
        try button(sut).tap()
        await waitUntil { !h.todos.calls.isEmpty }
        #expect(h.todos.calls == [.added(TodoDraft(listID: "inbox", title: "Call", notes: "", due: due))])
    }

    @Test func theAddFieldShowsADueChip() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodoAddField(listID: "inbox", title: ""), h).inspect()
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.add.due") }
    }

    @Test func todayGivesTheAddFieldADueOfToday() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodoItemsColumn(selection: .smart(.today)), h).inspect()
        let field = try sut.find(TodoAddField.self).actualView()
        #expect(field.due == TodoDue(date: day(2026, 3, 4), hasTime: false))
    }

    @Test func aListPageGivesTheAddFieldNoDue() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodoItemsColumn(selection: .list("inbox")), h).inspect()
        #expect(try sut.find(TodoAddField.self).actualView().due == nil)
    }

    @Test func aPartlySavedEditShowsTheMoveError() async throws {
        let h = await EngineHarness.pageFixture()
        let t = try #require(h.engine.todoSnapshot.todos.first { $0.id == "a" })
        let sut = try hosted(TodoEditCard(todo: t, failure: Copywriter.todoMoveFailed, onClose: {}), h).inspect()
        #expect(throws: Never.self) { try sut.find(text: Copywriter.todoMoveFailed) }
    }
}
