import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoDueMerge")
struct EngineTodoDueMergeTests {
    private let a = makeTodo("a", "Write report", due: timedDue(10, 30))
    private let b = makeTodo("b", "Call Sam", due: timedDue(10, 40))

    private func harness(_ todos: [Todo]) async -> EngineHarness {
        await EngineHarness.todoTracker(todos: todos) { $0.prefs.tracker.askEveryMinutes = 90 }
    }

    @Test func aLaterTodoJoinsTheOpenDuePrompt() async {
        let h = await harness([a, b])
        h.advance(minutes: 30)
        #expect(h.engine.trackerPrompt?.todoIDs == ["a"])
        h.advance(minutes: 10)
        #expect(h.promptKind == .todoDue)
        #expect(h.engine.trackerPrompt?.todoIDs == ["a", "b"])
        #expect(h.engine.trackerPromptState(.todoDue)?.todos.map(\.id) == ["a", "b"])
    }

    @Test func aTodoDueDuringAnEventAskWaitsAndShowsAfterIt() async {
        let h = await harness([a])
        let n = day(2026, 3, 4, 10)
        h.engine.setTrackerPrompt(PromptState(kind: .eventAsk, shownAt: n, askTime: n, eventID: "e1"))
        h.advance(minutes: 30)
        #expect(h.promptKind == .eventAsk)
        h.advance(minutes: 10)
        #expect(h.promptKind == .eventAsk)
        h.engine.closeTrackerPrompt()
        h.advance(minutes: 1)
        #expect(h.promptKind == .todoDue)
        #expect(h.engine.trackerPrompt?.todoIDs == ["a"])
    }

    @Test func doneRemovesOnlyThatTodo() async {
        let together = makeTodo("b", "Call Sam", due: timedDue(10, 30))
        let h = await harness([a, together])
        h.advance(minutes: 30)
        h.engine.doneTodo("a")
        #expect(h.promptKind == .todoDue)
        #expect(h.engine.trackerPrompt?.todoIDs == ["b"])
        h.engine.doneTodo("b")
        #expect(h.promptKind == nil)
    }

    @Test func onlyDueMomentsInsideTrackerHoursAreDeadlines() async {
        let late = makeTodo("c", "Late", due: timedDue(20, 30))
        let h = await harness([a, late])
        #expect(h.engine.todoDueDeadlines(after: day(2026, 3, 4, 10)) == [day(2026, 3, 4, 10, 30)])
    }
}
