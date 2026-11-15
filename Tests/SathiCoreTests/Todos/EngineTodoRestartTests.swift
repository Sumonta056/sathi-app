import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoRestart")
struct EngineTodoRestartTests {
    private let report = makeTodo("a", "Write report", due: timedDue(10, 30))

    private func restart(_ old: EngineHarness, todos: [Todo]) -> EngineHarness {
        let h = EngineHarness.restartedTracker(from: old, at: day(2026, 3, 4, 10, 45))
        h.todos.listsValue = [makeTodoList("inbox")]
        h.todos.todosValue = todos
        h.engine.start()
        return h
    }

    private func savedDuePrompt() async -> EngineHarness {
        let h = await EngineHarness.todoTracker(todos: [report]) { $0.prefs.tracker.askEveryMinutes = 60 }
        h.advance(minutes: 30)
        return h
    }

    @Test func aSavedDuePromptWaitsForTheFirstReadThenShowsItsTodo() async {
        let old = await savedDuePrompt()
        #expect(old.promptKind == .todoDue)
        let h = restart(old, todos: [report])
        #expect(!h.presenter.shownPrompts.contains(.todoDue))
        await h.engine.refreshTodosNow()
        #expect(h.presenter.shownPrompts.contains(.todoDue))
        #expect(h.engine.trackerPromptState(.todoDue)?.todos.map(\.id) == ["a"])
        #expect(h.engine.trackerPromptState(.todoDue).map { ActivityPromptBuilder.screen($0).title } == "Write report")
    }

    @Test func aSavedDuePromptClosesWhenItsTodoIsGone() async {
        let old = await savedDuePrompt()
        let h = restart(old, todos: [])
        await h.engine.refreshTodosNow()
        #expect(h.promptKind != .todoDue)
        #expect(!h.presenter.shownPrompts.contains(.todoDue))
    }

    @Test func aSavedEndsPromptKeepsItsMarkDoneCard() async {
        let report = makeTodo("a", "Write report", due: timedDue(9, 30))
        let old = await EngineHarness.todoTracker(todos: [report], running: nil) { $0.prefs.tracker.askEveryMinutes = 60 }
        old.engine.closeTrackerPrompt()
        old.engine.startTodo("a", draft: ActivityDraft(text: "Write report", length: .minutes(30)))
        old.advance(minutes: 30)
        #expect(old.engine.trackerPromptState(.stillOnIt)?.todoDoneAsk?.id == "a")
        let h = restart(old, todos: [report])
        #expect(!h.presenter.shownPrompts.contains(.stillOnIt))
        await h.engine.refreshTodosNow()
        #expect(h.presenter.shownPrompts.contains(.stillOnIt))
        #expect(h.engine.trackerPromptState(.stillOnIt)?.todoDoneAsk?.id == "a")
    }

    @Test func aCardDoesNotCountAsShownBeforeTheFirstRead() async {
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 10)) {
            $0.prefs.todos.isOn = true
            $0.prefs.tracker.askEveryMinutes = 60
        }
        h.todos.listsValue = [makeTodoList("inbox")]
        h.todos.todosValue = [report]
        h.engine.startTodo("a", draft: ActivityDraft(text: "Write report", length: .minutes(30)))
        h.advance(minutes: 30)
        #expect(h.running?.askedTodoDone == false)
        h.engine.start()
        await h.engine.refreshTodosNow()
        #expect(h.running?.askedTodoDone == true)
        #expect(h.engine.trackerPromptState(.stillOnIt)?.todoDoneAsk?.id == "a")
    }
}
