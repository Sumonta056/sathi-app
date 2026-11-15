import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todos settings")
struct TodosSettingsTests {
    private func page(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(TodosSettingsPage(), h).inspect()
    }

    @Test func offShowsOnlyTheSwitch() async throws {
        let h = await EngineHarness.pageFixture()
        await h.engine.setTodosOn(false)
        let sut = try page(h)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityLabel: "To-dos") }
        #expect((try? sut.find(viewWithAccessibilityLabel: "Ask when due")) == nil)
        #expect((try? sut.find(viewWithAccessibilityLabel: "Inbox")) == nil)
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "settings.todos.access.allowed")) == nil)
    }

    @Test func tappingTheSwitchTurnsTodosOnAndAsksForAccess() async throws {
        let h = await EngineHarness.todosReady(on: false)
        h.todos.access = .notAsked
        h.todos.accessAfterRequest = .allowed
        let sut = try page(h)
        try Find.button(sut, label: "To-dos").tap()
        await waitUntil { h.engine.data.prefs.todos.isOn && h.todos.requestCount == 1 }
        #expect(h.engine.data.prefs.todos.isOn)
        #expect(h.todos.requestCount == 1)
    }

    @Test func tappingTheSwitchWhenOnTurnsTodosOff() async throws {
        let h = await EngineHarness.pageFixture()
        try Find.button(page(h), label: "To-dos").tap()
        await waitUntil { !h.engine.data.prefs.todos.isOn }
        #expect(!h.engine.data.prefs.todos.isOn)
        #expect(h.engine.todoSnapshot == .empty)
    }

    @Test func allowedShowsTheAllowedStatus() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try page(h)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "settings.todos.access.allowed") }
        #expect(throws: Never.self) { try sut.find(text: Copywriter.todosSettingsAllowed) }
    }

    @Test func notAskedShowsAllowRemindersAccess() async throws {
        let h = await EngineHarness.todosReady(access: .notAsked)
        h.todos.accessAfterRequest = .allowed
        let sut = try page(h)
        try Find.button(sut, holding: "Allow Reminders access").tap()
        await waitUntil { h.todos.requestCount == 1 }
        #expect(h.todos.requestCount == 1)
    }

    @Test func deniedShowsOpenSystemSettings() async throws {
        let h = await EngineHarness.todosReady(access: .denied)
        let sut = try page(h)
        try Find.button(sut, holding: "Open System Settings").tap()
        #expect(h.links.opened.map(\.absoluteString) == [todoRemindersPrivacyURL])
    }

    @Test func listsEveryListWithAShownSwitch() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try page(h)
        for name in ["Inbox", "Work", "Shared"] {
            #expect(throws: Never.self) { try sut.find(viewWithAccessibilityLabel: name) }
        }
    }

    @Test func hiddenListsStayInTheListWithTheSwitchOff() async throws {
        let h = await EngineHarness.pageFixture()
        h.engine.setTodoListShown("work", false)
        let sut = try page(h)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityLabel: "Work") }
    }

    @Test func tappingAListSwitchHidesAndShowsIt() async throws {
        let h = await EngineHarness.pageFixture()
        try Find.button(page(h), label: "Work").tap()
        #expect(h.engine.data.prefs.todos.hiddenListIDs == ["work"])
        h.engine.data.prefs.todos.hiddenListIDs = ["work"]
        try Find.button(page(h), label: "Work").tap()
        #expect(h.engine.data.prefs.todos.hiddenListIDs.isEmpty)
    }

    @Test func askWhenDueSwitchFlipsThePref() async throws {
        let h = await EngineHarness.pageFixture()
        #expect(h.engine.data.prefs.todos.askWhenDue)
        try Find.button(page(h), label: "Ask when due").tap()
        #expect(!h.engine.data.prefs.todos.askWhenDue)
    }

    @Test func deniedShowsNoListSection() async throws {
        let h = await EngineHarness.todosReady(access: .denied)
        let sut = try page(h)
        #expect((try? sut.find(viewWithAccessibilityLabel: "Inbox")) == nil)
    }
}
