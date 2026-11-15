import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoFlow")
struct EngineTodoFlowTests {
    private func fresh(access: TodoAccess, after: TodoAccess? = nil, on: Bool = false) -> EngineHarness {
        let h = EngineHarness { $0.prefs.todos.isOn = on }
        h.todos.listsValue = [makeTodoList("inbox", "Inbox")]
        h.todos.todosValue = [makeTodo("a", list: "inbox")]
        h.todos.access = access
        h.todos.accessAfterRequest = after
        return h
    }

    @Test func turningOnAsksForAccessOnce() async {
        let h = fresh(access: .notAsked, after: .allowed)
        await h.engine.setTodosOn(true)
        #expect(h.todos.requestCount == 1)
        #expect(h.engine.data.prefs.todos.isOn)
        #expect(h.engine.todoAccess == .allowed)
        #expect(h.engine.todoSnapshot.lists.map(\.id) == ["inbox"])
        await h.engine.refreshTodosNow()
        #expect(h.todos.requestCount == 1)
    }

    @Test func turningOnWhenAccessIsAlreadyAllowedDoesNotAsk() async {
        let h = fresh(access: .allowed)
        await h.engine.setTodosOn(true)
        #expect(h.todos.requestCount == 0)
        #expect(h.engine.todoAccess == .allowed)
        #expect(h.engine.todoSnapshot.open.map(\.id) == ["a"])
    }

    @Test func turningOnWhenAccessIsDeniedDoesNotAskAndShowsTheGate() async {
        let h = fresh(access: .denied)
        await h.engine.setTodosOn(true)
        #expect(h.todos.requestCount == 0)
        #expect(h.engine.data.prefs.todos.isOn)
        #expect(h.engine.todoAccess == .denied)
        #expect(h.engine.todoSnapshot == .empty)
        #expect(h.todos.readRequests.isEmpty)
    }

    @Test func deniedAnswerShowsTheGateAndReadsNothing() async {
        let h = fresh(access: .notAsked, after: .denied)
        await h.engine.setTodosOn(true)
        #expect(h.todos.requestCount == 1)
        #expect(h.engine.todoAccess == .denied)
        #expect(h.engine.todoSnapshot == .empty)
        #expect(h.todos.readRequests.isEmpty)
    }

    @Test func turningOffEmptiesTheSnapshotAndNeverAsks() async {
        let h = fresh(access: .allowed, on: true)
        await h.engine.refreshTodosNow()
        #expect(!h.engine.todoSnapshot.open.isEmpty)
        await h.engine.setTodosOn(false)
        #expect(!h.engine.data.prefs.todos.isOn)
        #expect(h.engine.todoSnapshot == .empty)
        #expect(h.todos.requestCount == 0)
    }

    @Test func turningOnAgainAfterOffAsksAgainOnlyWhenNotAsked() async {
        let h = fresh(access: .notAsked, after: .allowed)
        await h.engine.setTodosOn(true)
        await h.engine.setTodosOn(false)
        h.todos.access = .notAsked
        await h.engine.setTodosOn(true)
        #expect(h.todos.requestCount == 2)
        #expect(h.engine.todoAccess == .allowed)
    }

    @Test func gateButtonAsksForAccessAndThenLoads() async {
        let h = fresh(access: .notAsked, after: .allowed, on: true)
        await h.engine.refreshTodosNow()
        #expect(h.engine.todoAccess == .notAsked)
        await h.engine.requestTodoAccess()
        #expect(h.todos.requestCount == 1)
        #expect(h.engine.todoAccess == .allowed)
        #expect(h.engine.todoSnapshot.open.map(\.id) == ["a"])
    }

    @Test func gateButtonKeepsTheGateWhenTheAnswerIsNo() async {
        let h = fresh(access: .notAsked, after: .denied, on: true)
        await h.engine.requestTodoAccess()
        #expect(h.engine.todoAccess == .denied)
        #expect(h.engine.todoSnapshot == .empty)
    }

    @Test func openTodoSettingsOpensThePrivacyPane() {
        let h = fresh(access: .denied, on: true)
        h.engine.openTodoSettings()
        #expect(h.links.opened.map(\.absoluteString) == [todoRemindersPrivacyURL])
    }

    @Test func openMainTodosShowsThePageWhenOn() {
        let h = fresh(access: .allowed, on: true)
        h.engine.openMain(.todos)
        #expect(h.presenter.calls.last == .showMain(.todos))
    }

    @Test func openMainTodosFallsBackToTodayWhenOff() {
        let h = fresh(access: .allowed, on: false)
        h.engine.openMain(.todos)
        #expect(h.presenter.calls.last == .showMain(.today))
    }
}
