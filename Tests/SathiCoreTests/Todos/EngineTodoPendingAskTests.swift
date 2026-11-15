import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoPendingAsk")
struct EngineTodoPendingAskTests {
    private let report = makeTodo("a", "Write report", due: timedDue(9, 30))

    private func working(at start: Date = day(2026, 3, 4, 10), todos: [Todo]? = nil) async -> EngineHarness {
        let h = await EngineHarness.todoTracker(at: start, todos: todos ?? [report], running: nil) {
            $0.prefs.tracker.askEveryMinutes = 60
        }
        h.engine.closeTrackerPrompt()
        h.engine.startTodo("a", draft: ActivityDraft(text: "Write report", length: .minutes(120)))
        h.advance(minutes: 10)
        return h
    }

    private func card(_ h: EngineHarness) -> String? {
        guard let kind = h.promptKind else { return nil }
        return h.engine.trackerPromptState(kind)?.todoDoneAsk?.id
    }

    private func pending(_ h: EngineHarness) -> String? { h.engine.data.live.tracker.pendingTodoAsk }

    @Test func aSwitchLeavesAPendingAskForTheNextPrompt() async {
        let h = await working()
        h.engine.startActivity(ActivityDraft(text: "Email", length: .minutes(30)))
        #expect(pending(h) == "a")
        h.engine.openTrackerPanel()
        #expect(card(h) == "a")
        #expect(pending(h) == nil)
        h.engine.closeTrackerPrompt()
        h.engine.openTrackerPanel()
        #expect(card(h) == nil)
    }

    @Test func switchingToAnotherTodoAlsoLeavesAPendingAsk() async {
        let h = await working(todos: [report, makeTodo("b", "Call Sam")])
        h.engine.startTodo("b", draft: ActivityDraft(text: "Call Sam"))
        #expect(pending(h) == "a")
        #expect(h.running?.todoID == "b")
    }

    @Test func stopFromTheMenuShowsTheCardOnItsPrompt() async {
        let h = await working()
        h.engine.doneActivity()
        #expect(card(h) == "a")
        h.engine.startActivity(ActivityDraft(text: "Email", length: .minutes(30)))
        #expect(pending(h) == nil)
        h.engine.openTrackerPanel()
        #expect(card(h) == nil)
    }

    @Test func awayLeavesAPendingAskForTheWelcomeBack() async {
        let h = await working()
        h.engine.presenceChanged(.locked)
        #expect(h.running == nil)
        #expect(pending(h) == "a")
        h.advance(minutes: 5)
        h.engine.presenceChanged(.unlocked)
        #expect(h.promptKind == .welcomeBack)
        #expect(card(h) == "a")
        #expect(pending(h) == nil)
    }

    @Test func theMidnightSplitLeavesAPendingAsk() async {
        let h = await working(at: day(2026, 3, 4, 23, 10))
        h.advance(minutes: 30)
        h.advance(minutes: 30)
        #expect(h.running == nil)
        #expect(pending(h) == "a")
        h.engine.openTrackerPanel()
        #expect(card(h) == "a")
    }

    @Test func aDoneTodoClearsThePendingAskWithNoCard() async {
        let h = await working()
        h.engine.startActivity(ActivityDraft(text: "Email", length: .minutes(30)))
        await h.replaceTodos([makeTodo("a", "Write report", due: timedDue(9, 30), done: true, doneAt: day(2026, 3, 4, 10, 10))])
        h.engine.openTrackerPanel()
        #expect(card(h) == nil)
        #expect(pending(h) == nil)
    }

    @Test func thePendingAskIsSavedAndOldStateLoadsWithoutIt() throws {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        let old = try d.decode(LiveState.self, from: Data(#"{"tracker":{}}"#.utf8))
        #expect(old.tracker.pendingTodoAsk == nil)
        let bad = try d.decode(LiveState.self, from: Data(#"{"tracker":{"pendingTodoAsk":3}}"#.utf8))
        #expect(bad.tracker.pendingTodoAsk == nil)
        var l = LiveState()
        l.tracker.pendingTodoAsk = "a"
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        #expect(try d.decode(LiveState.self, from: e.encode(l)).tracker.pendingTodoAsk == "a")
    }
}
