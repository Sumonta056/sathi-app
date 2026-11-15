import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoSync")
struct EngineTodoSyncTests {
    private func harness(on: Bool = true, hidden: Set<String> = []) -> EngineHarness {
        let h = EngineHarness { state in
            state.prefs.todos.isOn = on
            state.prefs.todos.hiddenListIDs = hidden
        }
        h.todos.listsValue = [makeTodoList("inbox"), makeTodoList("work")]
        h.todos.todosValue = [
            makeTodo("a", list: "inbox"),
            makeTodo("b", list: "work")
        ]
        return h
    }

    private func settle(_ h: EngineHarness) async {
        await h.engine.todoRuntime.refreshTask?.value
    }

    @Test func listenerStartsWhenTurnedOnAndStopsWhenOff() {
        let h = harness(on: false)
        h.engine.start()
        #expect(!h.calendarChanges.isListening)
        h.engine.data.prefs.todos.isOn = true
        #expect(h.calendarChanges.isListening)
        h.engine.data.prefs.todos.isOn = false
        #expect(!h.calendarChanges.isListening)
    }

    @Test func turningOffEmptiesTheSnapshot() async {
        let h = harness()
        h.engine.start()
        await settle(h)
        h.engine.data.prefs.todos.isOn = false
        #expect(h.engine.todoSnapshot == .empty)
    }

    @Test func hidingAListReloads() async {
        let h = harness()
        h.engine.start()
        await settle(h)
        h.engine.data.prefs.todos.hiddenListIDs = ["work"]
        await settle(h)
        #expect(h.engine.todoSnapshot.lists.map(\.id) == ["inbox"])
    }

    @Test func offDoesNotReadOnAStoreChange() async {
        let h = harness(on: false)
        h.engine.start()
        h.calendarChanges.fire()
        await settle(h)
        #expect(h.todos.readRequests.isEmpty)
    }

    private func trackerHarness() -> EngineHarness {
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 10)) {
            $0.prefs.todos.isOn = true
            $0.prefs.tracker.readsEvents = true
            $0.prefs.tracker.readCalendarIDs = ["work"]
        }
        h.engine.start()
        return h
    }

    @Test func todosOffKeepsListeningWhileTheCalendarPageIsOpen() {
        let h = harness()
        h.engine.start()
        h.engine.calendarPageOpened()
        h.engine.data.prefs.todos.isOn = false
        #expect(h.calendarChanges.isListening)
    }

    @Test func todosOffKeepsListeningWhileTheTrackerReadsEvents() {
        let h = trackerHarness()
        #expect(h.calendarChanges.isListening)
        h.engine.data.prefs.todos.isOn = false
        #expect(h.calendarChanges.isListening)
    }

    @Test func closingTheCalendarPageKeepsListeningWhileTodosIsOn() {
        let h = harness()
        h.engine.start()
        h.engine.calendarPageOpened()
        h.engine.calendarPageClosed()
        #expect(h.calendarChanges.isListening)
    }

    @Test func listenerStopsOnlyWhenPageTrackerAndTodosAreAllOff() {
        let h = trackerHarness()
        h.engine.calendarPageOpened()
        h.engine.data.prefs.todos.isOn = false
        h.engine.data.prefs.tracker.isOn = false
        #expect(h.calendarChanges.isListening)
        h.engine.calendarPageClosed()
        #expect(!h.calendarChanges.isListening)
    }
}
