import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoAwayRestore")
struct EngineTodoAwayRestoreTests {
    private let report = makeTodo("a", "Write report", due: timedDue(9, 30))

    private func idleAway(ready: Bool = true) async -> EngineHarness {
        let h = await EngineHarness.todoTracker(todos: [report], running: nil) { $0.prefs.tracker.askEveryMinutes = 60 }
        h.engine.closeTrackerPrompt()
        h.engine.startTodo("a", draft: ActivityDraft(text: "Write report", length: .minutes(120)))
        h.presence.idleSeconds = 40 * 60
        h.advance(minutes: 45)
        h.engine.todoDueReady = ready
        h.presence.idleSeconds = 0
        h.advance(minutes: 5)
        return h
    }

    private func card(_ h: EngineHarness) -> String? {
        guard let kind = h.promptKind else { return nil }
        return h.engine.trackerPromptState(kind)?.todoDoneAsk?.id
    }

    private func pending(_ h: EngineHarness) -> String? { h.engine.data.live.tracker.pendingTodoAsk }

    @Test func aDrawnCardIsNotShownAgainAfterIWasHere() async {
        let h = await idleAway()
        #expect(h.promptKind == .welcomeBack)
        #expect(card(h) == "a")
        h.engine.iWasHere()
        #expect(h.running?.todoID == "a")
        #expect(h.running?.askedTodoDone == true)
        #expect(pending(h) == nil)
        h.engine.startActivity(ActivityDraft(text: "Email", length: .minutes(30)))
        #expect(pending(h) == nil)
        h.engine.openTrackerPanel()
        #expect(card(h) == nil)
    }

    @Test func iWasHereBeforeTheCardIsDrawnAsksOnceWhenTheActivityEnds() async {
        let h = await idleAway(ready: false)
        #expect(h.promptKind == .welcomeBack)
        h.engine.iWasHere()
        #expect(h.running?.todoID == "a")
        #expect(h.running?.askedTodoDone == false)
        #expect(pending(h) == nil)
        await h.replaceTodos([report])
        h.engine.openTrackerPanel()
        #expect(card(h) == nil)
        h.engine.startActivity(ActivityDraft(text: "Email", length: .minutes(30)))
        #expect(pending(h) == "a")
        h.engine.openTrackerPanel()
        #expect(card(h) == "a")
        h.engine.closeTrackerPrompt()
        h.engine.openTrackerPanel()
        #expect(card(h) == nil)
    }

    @Test func aPromptThatGetsACardWaitsForTheFirstRead() async {
        let h = await EngineHarness.todoTracker(todos: [report], running: nil) { $0.prefs.tracker.askEveryMinutes = 60 }
        h.engine.closeTrackerPrompt()
        h.engine.startTodo("a", draft: ActivityDraft(text: "Write report", length: .minutes(120)))
        h.engine.startActivity(ActivityDraft(text: "Email", length: .minutes(30)))
        h.engine.todoDueReady = false
        h.engine.openTrackerPanel()
        #expect(!h.presenter.shownPrompts.contains(.center))
        await h.replaceTodos([report])
        #expect(h.presenter.shownPrompts.contains(.center))
        #expect(card(h) == "a")
    }

    @Test func turningTodosOffForgetsThePendingAskAndTheRead() async {
        let h = await EngineHarness.todoTracker(todos: [report], running: nil) { $0.prefs.tracker.askEveryMinutes = 60 }
        h.engine.closeTrackerPrompt()
        h.engine.startTodo("a", draft: ActivityDraft(text: "Write report", length: .minutes(120)))
        h.engine.startActivity(ActivityDraft(text: "Email", length: .minutes(30)))
        #expect(pending(h) == "a")
        h.engine.data.prefs.todos.isOn = false
        #expect(pending(h) == nil)
        #expect(!h.engine.todoDueReady)
    }
}
