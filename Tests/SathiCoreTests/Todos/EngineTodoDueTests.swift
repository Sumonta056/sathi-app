import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoDue")
struct EngineTodoDueTests {
    private func report(_ id: String = "a", due: TodoDue? = timedDue(10, 30), list: String = "inbox", done: Bool = false) -> Todo {
        makeTodo(id, "Write report", list: list, due: due, done: done, doneAt: done ? day(2026, 3, 4, 9) : nil)
    }

    private func opens(_ h: EngineHarness, minutes: Double = 30) -> Bool {
        h.advance(minutes: minutes)
        return h.promptKind == .todoDue
    }

    @Test func opensAtTheDueMomentInsideTrackerHours() async {
        let h = await EngineHarness.todoTracker(todos: [report()])
        #expect(h.promptKind == nil)
        h.advance(minutes: 29)
        #expect(h.promptKind == nil)
        h.advance(minutes: 1)
        #expect(h.promptKind == .todoDue)
        #expect(h.engine.trackerPrompt?.todoIDs == ["a"])
        #expect(h.presenter.shownPrompts.contains(.todoDue))
    }

    @Test func replacesAnOpenWhatNowPrompt() async {
        let h = await EngineHarness.todoTracker(todos: [report()], running: nil)
        #expect(h.promptKind == .whatNow)
        #expect(opens(h))
    }

    @Test func noPromptWhenTheTrackerIsOff() async {
        let h = await EngineHarness.todoTracker(todos: [report()], trackerOn: false)
        #expect(!opens(h))
        #expect(h.engine.trackerPrompt == nil)
    }

    @Test func noPromptWhenAskWhenDueIsOff() async {
        let h = await EngineHarness.todoTracker(todos: [report()], askWhenDue: false)
        #expect(!opens(h))
    }

    @Test func noPromptForATodoWithoutATime() async {
        let h = await EngineHarness.todoTracker(todos: [report(due: dateOnlyDue())])
        #expect(!opens(h))
    }

    @Test func noPromptForADoneTodo() async {
        let h = await EngineHarness.todoTracker(todos: [report(done: true)])
        #expect(!opens(h))
    }

    @Test func noPromptForAHiddenList() async {
        let h = await EngineHarness.todoTracker(
            todos: [report(list: "work")],
            lists: [makeTodoList("inbox"), makeTodoList("work")]
        ) { $0.prefs.todos.hiddenListIDs = ["work"] }
        #expect(!opens(h))
    }

    @Test func noPromptWhenTheTodosAccessIsDenied() async {
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 10)) { $0.prefs.todos.isOn = true }
        h.todos.access = .denied
        h.todos.listsValue = [makeTodoList("inbox")]
        h.todos.todosValue = [report()]
        h.engine.start()
        await h.engine.refreshTodosNow()
        h.engine.startActivity(ActivityDraft(text: "Code review", length: .minutes(120)))
        #expect(!opens(h))
    }

    @Test func noPromptOutsideTrackerHours() async {
        let h = await EngineHarness.todoTracker(at: day(2026, 3, 4, 17), todos: [report(due: timedDue(18, 30))])
        #expect(!opens(h, minutes: 90))
        h.advance(minutes: 60)
        #expect(h.promptKind != .todoDue)
    }

    @Test func noPromptOnADayTheTrackerIsNotOn() async {
        let h = await EngineHarness.todoTracker(
            at: day(2026, 3, 7, 10),
            todos: [report(due: timedDue(10, 30, on: 7))],
            running: nil
        )
        #expect(!opens(h))
    }

    @Test func aDueMomentDuringQuietTimeNeverOpensLater() async {
        let draft = ActivityDraft(text: "Deep work", length: .minutes(60), quiet: true)
        let h = await EngineHarness.todoTracker(todos: [report()], running: draft)
        #expect(!opens(h))
        h.advance(minutes: 30)
        h.advance(minutes: 30)
        #expect(!h.presenter.shownPrompts.contains(.todoDue))
    }

    @Test func aDueMomentThatPassedWhileSathiWasClosedOpensNothing() async {
        let h = await EngineHarness.todoTracker(at: day(2026, 3, 4, 11), todos: [report()])
        h.advance(minutes: 5)
        #expect(!h.presenter.shownPrompts.contains(.todoDue))
    }

    @Test func opensOneTimeOnly() async {
        let h = await EngineHarness.todoTracker(todos: [report()])
        #expect(opens(h))
        h.engine.closeTrackerPrompt()
        h.advance(minutes: 1)
        h.advance(minutes: 10)
        #expect(h.presenter.shownPrompts.filter { $0 == .todoDue }.count == 1)
        #expect(h.engine.trackerPrompt?.kind != .todoDue)
    }

    @Test func aChangedDueTimeCanOpenItAgain() async {
        let h = await EngineHarness.todoTracker(todos: [report()])
        #expect(opens(h))
        h.engine.closeTrackerPrompt()
        await h.replaceTodos([report(due: timedDue(11))])
        h.advance(minutes: 30)
        #expect(h.promptKind == .todoDue)
        #expect(h.presenter.shownPrompts.filter { $0 == .todoDue }.count == 2)
    }

    @Test func twoTodosDueTogetherShareOnePrompt() async {
        let a = makeTodo("a", "Write report", due: timedDue(10, 30))
        let b = makeTodo("b", "Call Sam", due: TodoDue(date: day(2026, 3, 4, 10, 30).addingTimeInterval(30), hasTime: true))
        let h = await EngineHarness.todoTracker(todos: [b, a])
        #expect(opens(h))
        #expect(h.engine.trackerPrompt?.todoIDs == ["a", "b"])
        #expect(h.engine.trackerPromptState(.todoDue)?.todos.map(\.id) == ["a", "b"])
        #expect(h.presenter.shownPrompts.filter { $0 == .todoDue }.count == 1)
    }

    @Test func theDueMomentShortensTheTickDelay() async {
        let h = await EngineHarness.todoTracker(todos: [])
        #expect(h.engine.nextTickDelay() > 120)
        await h.replaceTodos([report(due: timedDue(10, 2))])
        #expect(abs(h.engine.nextTickDelay() - 120) < 1)
    }
}
