import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todo list form")
struct TodoListFormTests {
    private func harness() async -> EngineHarness {
        let h = await EngineHarness.pageFixture()
        h.todos.accountsValue = [
            TodoAccount(id: "ex", name: "Exchange", allowsNewLists: true),
            TodoAccount(id: "ic", name: "iCloud", allowsNewLists: true, isICloud: true),
            TodoAccount(id: "lk", name: "Locked", allowsNewLists: false)
        ]
        return h
    }

    private func create(
        _ h: EngineHarness,
        name: String = "",
        color: String = Limits.todoListColors[0],
        account: String? = nil,
        onClose: @escaping () -> Void = {}
    ) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(TodoListForm(name: name, colorHex: color, accountID: account, onClose: onClose), h).inspect()
    }

    private func rename(_ h: EngineHarness, _ id: String, name: String? = nil) throws -> InspectableView<ViewType.ClassifiedView> {
        let list = h.engine.todoSnapshot.lists.first { $0.id == id }!
        return try hosted(TodoListForm(list: list, name: name ?? list.name, onClose: {}), h).inspect()
    }

    private func button(_ sut: InspectableView<some BaseViewType>, _ id: String) throws -> InspectableView<ViewType.Button> {
        try sut.find(viewWithAccessibilityIdentifier: id).find(ViewType.Button.self, relation: .parent)
    }

    @Test func createShowsTwelveColorSwatches() async throws {
        let sut = try await create(harness())
        for i in 0 ..< Limits.todoListColors.count {
            #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.listform.color.\(i)") }
        }
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.listform.color.12")) == nil)
    }

    @Test func createOffersOnlyAccountsThatAllowNewLists() async throws {
        let sut = try await create(harness())
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.listform.account.ic") }
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.listform.account.ex") }
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.listform.account.lk")) == nil)
    }

    @Test func createIsDisabledForABlankName() async throws {
        let h = await harness()
        #expect(try button(create(h, name: "   "), "todos.listform.save").isDisabled())
        #expect(try !button(create(h, name: "Trips"), "todos.listform.save").isDisabled())
    }

    @Test func createWritesTheDraftWithTheDefaultAccountAndCloses() async throws {
        let h = await harness()
        var closed = 0
        let color = Limits.todoListColors[4]
        try button(create(h, name: " Trips ", color: color, onClose: { closed += 1 }), "todos.listform.save").tap()
        await waitUntil { !h.todos.calls.isEmpty }
        #expect(h.todos.calls == [.listCreated(TodoListDraft(name: "Trips", colorHex: color, accountID: "ic"))])
        await waitUntil { closed == 1 }
        #expect(closed == 1)
    }

    @Test func createUsesTheGivenAccount() async throws {
        let h = await harness()
        try button(create(h, name: "Trips", account: "ex"), "todos.listform.save").tap()
        await waitUntil { !h.todos.calls.isEmpty }
        #expect(h.todos.calls == [.listCreated(TodoListDraft(name: "Trips", colorHex: Limits.todoListColors[0], accountID: "ex"))])
    }

    @Test func renameShowsNoColorOrAccountPickers() async throws {
        let sut = try await rename(harness(), "inbox")
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.listform.color.0")) == nil)
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.listform.account.ic")) == nil)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.listform.name") }
    }

    @Test func renameWritesTheTrimmedName() async throws {
        let h = await harness()
        try button(rename(h, "inbox", name: "  Home "), "todos.listform.save").tap()
        await waitUntil { !h.todos.calls.isEmpty }
        #expect(h.todos.calls == [.listRenamed("inbox", "Home")])
    }

    @Test func renameIsDisabledForABlankName() async throws {
        let h = await harness()
        #expect(try button(rename(h, "inbox", name: " "), "todos.listform.save").isDisabled())
    }

    @Test func cancelClosesAndWritesNothing() async throws {
        let h = await harness()
        var closed = 0
        try button(create(h, name: "Trips", onClose: { closed += 1 }), "todos.listform.cancel").tap()
        #expect(closed == 1)
        #expect(h.todos.calls.isEmpty)
    }
}
