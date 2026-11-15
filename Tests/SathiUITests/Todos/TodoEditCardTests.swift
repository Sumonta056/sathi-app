import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todo edit card")
struct TodoEditCardTests {
    private func card(
        _ h: EngineHarness,
        _ todo: Todo,
        form: TodoEditForm? = nil,
        confirming: Bool = false,
        onClose: @escaping () -> Void = {}
    ) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(TodoEditCard(todo: todo, form: form, confirmingDelete: confirming, onClose: onClose), h).inspect()
    }

    private func todo(_ h: EngineHarness, _ id: String) -> Todo {
        h.engine.todoSnapshot.todos.first { $0.id == id }!
    }

    private func button(_ sut: InspectableView<some BaseViewType>, _ id: String) throws -> InspectableView<ViewType.Button> {
        try sut.find(viewWithAccessibilityIdentifier: id).find(ViewType.Button.self, relation: .parent)
    }

    @Test func hasTheFieldsAndButtons() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try card(h, todo(h, "a"))
        for id in ["todos.edit.title", "todos.edit.notes", "todos.edit.save", "todos.edit.cancel", "todos.edit.delete"] {
            #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: id) }
        }
    }

    @Test func offersEveryEditableListAsAChipButNotAReadOnlyOne() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try card(h, todo(h, "a"))
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.edit.list.inbox") }
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.edit.list.work") }
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.edit.list.ro")) == nil)
    }

    @Test func aReadOnlyListTodoHasNoSaveOrDelete() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try card(h, todo(h, "e"))
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.edit.save")) == nil)
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.edit.delete")) == nil)
    }

    @Test func repeatAndPriorityShowReadOnly() async throws {
        let h = await EngineHarness.pageFixture()
        var t = todo(h, "a")
        t.repeats = true
        t.priority = 1
        let sut = try card(h, t)
        #expect(throws: Never.self) { try sut.find(text: Copywriter.todoRepeats) }
        #expect(throws: Never.self) { try sut.find(text: "High") }
        let plain = try card(h, todo(h, "c"))
        #expect(Find.lacks(plain, text: Copywriter.todoRepeats))
    }

    @Test func saveIsDisabledForABlankTitle() async throws {
        let h = await EngineHarness.pageFixture()
        var form = TodoEditForm(todo: todo(h, "a"), calendar: .current)
        form.title = "  "
        #expect(try button(card(h, todo(h, "a"), form: form), "todos.edit.save").isDisabled())
        #expect(try !button(card(h, todo(h, "a")), "todos.edit.save").isDisabled())
    }

    @Test func saveWritesTheEditAndCloses() async throws {
        let h = await EngineHarness.pageFixture()
        let t = todo(h, "a")
        var form = TodoEditForm(todo: t, calendar: .current)
        form.title = "Alpha 2"
        var closed = 0
        try button(card(h, t, form: form, onClose: { closed += 1 }), "todos.edit.save").tap()
        await waitUntil { !h.todos.calls.isEmpty }
        #expect(h.todos.calls == [.updated("a", form.edit(calendar: .current))])
        await waitUntil { closed == 1 }
        #expect(closed == 1)
    }

    @Test func saveWithAnotherListAlsoMoves() async throws {
        let h = await EngineHarness.pageFixture()
        let t = todo(h, "a")
        var form = TodoEditForm(todo: t, calendar: .current)
        form.listID = "work"
        try button(card(h, t, form: form), "todos.edit.save").tap()
        await waitUntil { h.todos.calls.count == 2 }
        #expect(h.todos.calls == [.updated("a", form.edit(calendar: .current)), .moved("a", "work")])
    }

    @Test func cancelClosesAndWritesNothing() async throws {
        let h = await EngineHarness.pageFixture()
        var closed = 0
        try button(card(h, todo(h, "a"), onClose: { closed += 1 }), "todos.edit.cancel").tap()
        #expect(closed == 1)
        #expect(h.todos.calls.isEmpty)
    }

    @Test func deleteAsksToConfirmFirst() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try card(h, todo(h, "a"))
        try button(sut, "todos.edit.delete").tap()
        #expect(h.todos.calls.isEmpty)
        #expect(Find.lacks(sut, text: Copywriter.todoDeleteConfirm("Alpha")))
    }

    @Test func confirmingShowsTheQuestionAndDeletes() async throws {
        let h = await EngineHarness.pageFixture()
        var closed = 0
        let sut = try card(h, todo(h, "a"), confirming: true, onClose: { closed += 1 })
        #expect(throws: Never.self) { try sut.find(text: Copywriter.todoDeleteConfirm("Alpha")) }
        try button(sut, "todos.edit.confirmDelete").tap()
        await waitUntil { !h.todos.calls.isEmpty }
        #expect(h.todos.calls == [.deleted("a")])
        await waitUntil { closed == 1 }
        #expect(closed == 1)
    }

    @Test func keepingCancelsTheConfirm() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try card(h, todo(h, "a"), confirming: true)
        try button(sut, "todos.edit.keep").tap()
        #expect(h.todos.calls.isEmpty)
    }

    @Test func theDueDateSwitchHasAnIdentifier() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try card(h, todo(h, "b"))
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.edit.hasDate") }
        #expect(throws: Never.self) { try sut.find(TimeMenu.self) }
    }

    @Test func aDateOnlyTodoShowsNoTimeMenu() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try card(h, todo(h, "a"))
        #expect((try? sut.find(TimeMenu.self)) == nil)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.edit.addTime") }
    }
}
