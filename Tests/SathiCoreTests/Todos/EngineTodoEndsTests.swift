import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoEnds")
struct EngineTodoEndsTests {
    private let report = makeTodo("a", "Write report", due: timedDue(9, 30))

    private func ended(todos: [Todo]? = nil, withTodo: Bool = true) async -> EngineHarness {
        let h = await EngineHarness.todoTracker(todos: todos ?? [report], running: nil)
        h.engine.closeTrackerPrompt()
        let draft = ActivityDraft(text: "Write report", length: .minutes(30))
        if withTodo { _ = h.engine.startTodo("a", draft: draft) } else { h.engine.startActivity(draft) }
        h.advance(minutes: 30)
        return h
    }

    private func ask(_ h: EngineHarness) -> Todo? { h.engine.trackerPromptState(.stillOnIt)?.todoDoneAsk }

    @Test func endingATodoActivityAsksToMarkItDone() async {
        let h = await ended()
        #expect(h.promptKind == .stillOnIt)
        #expect(ask(h)?.id == "a")
        #expect(h.engine.trackerPrompt?.todoIDs == ["a"])
        #expect(h.running?.askedTodoDone == true)
    }

    @Test func markDoneCallsSetDoneAndKeepsThePromptOpen() async {
        let h = await ended()
        h.engine.markTodoDone(true)
        #expect(h.todos.calls == [.doneSet("a", true)])
        #expect(ask(h) == nil)
        #expect(h.promptKind == .stillOnIt)
    }

    @Test func markDoneLogsNoActivity() async {
        let h = await ended()
        h.engine.markTodoDone(true)
        #expect(h.saved.isEmpty)
        #expect(h.running?.text == "Write report")
    }

    @Test func notYetWritesNothingAndNeverAsksAgain() async {
        let h = await ended()
        h.engine.markTodoDone(false)
        #expect(h.todos.calls.isEmpty)
        #expect(ask(h) == nil)
        h.engine.stillOnIt(minutes: 15)
        h.advance(minutes: 15)
        #expect(h.promptKind == .stillOnIt)
        #expect(ask(h) == nil)
        #expect(h.todos.calls.isEmpty)
    }

    @Test func anUnansweredCardIsNotShownAgainOnTheNextPrompt() async {
        let h = await ended()
        h.engine.stillOnIt(minutes: 15)
        h.advance(minutes: 15)
        #expect(h.promptKind == .stillOnIt)
        #expect(ask(h) == nil)
    }

    @Test func noCardForADoneTodo() async {
        let done = makeTodo("a", "Write report", due: timedDue(9, 30), done: true, doneAt: day(2026, 3, 4, 10, 10))
        let h = await ended(todos: [done])
        #expect(h.promptKind == .stillOnIt)
        #expect(ask(h) == nil)
    }

    @Test func noCardForAGoneTodo() async {
        let h = await ended(todos: [])
        #expect(ask(h) == nil)
    }

    @Test func noCardForAnActivityWithoutATodo() async {
        let h = await ended(withTodo: false)
        #expect(h.promptKind == .stillOnIt)
        #expect(ask(h) == nil)
    }

    @Test func noCardWhenTodosAreOff() async {
        let h = await ended()
        h.engine.stillOnIt(minutes: 15)
        h.engine.data.prefs.todos.isOn = false
        h.advance(minutes: 15)
        #expect(ask(h) == nil)
    }

    @Test func theCardIsOnTheEndsScreenOnly() async {
        let h = await ended()
        #expect(h.engine.trackerPromptState(.whatNow) == nil)
        let screen = h.engine.trackerPromptState(.stillOnIt).map { ActivityPromptBuilder.screen($0) }
        #expect(screen?.markDone == PromptMarkDone(todoID: "a", question: "Mark Write report done?"))
    }
}
