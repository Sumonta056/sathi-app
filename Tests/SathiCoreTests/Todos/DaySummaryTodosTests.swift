import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("DaySummaryTodos")
struct DaySummaryTodosTests {
    private func items() -> [Todo] {
        [
            makeTodo("d1", due: timedDue(9), done: true, doneAt: day(2026, 3, 4, 9, 30)),
            makeTodo("d2", done: true, doneAt: day(2026, 3, 4, 20)),
            makeTodo("old", done: true, doneAt: day(2026, 3, 3, 21)),
            makeTodo("l1", due: timedDue(23)),
            makeTodo("l2", due: dateOnlyDue()),
            makeTodo("late", due: dateOnlyDue(on: 2)),
            makeTodo("later", due: dateOnlyDue(on: 5)),
            makeTodo("nodate")
        ]
    }

    private func harness(
        on: Bool = true,
        access: TodoAccess = .allowed,
        hidden: Set<String> = [],
        configure: @escaping (inout Persisted) -> Void = { _ in }
    ) async -> EngineHarness {
        let h = EngineHarness(at: day(2026, 3, 4, 22)) {
            $0.prefs.todos.isOn = on
            $0.prefs.todos.hiddenListIDs = hidden
            configure(&$0)
        }
        h.todos.access = access
        h.todos.listsValue = [makeTodoList("inbox"), makeTodoList("work")]
        h.todos.todosValue = items()
        h.engine.start()
        await h.engine.refreshTodosNow()
        return h
    }

    @Test func countsDoneTodayAndLeftForToday() async {
        let h = await harness()
        #expect(h.engine.daySummary.todos == DaySummaryTodos(done: 2, left: 3))
    }

    @Test func aHiddenListIsNotCounted() async {
        let h = await harness(hidden: ["inbox"])
        #expect(h.engine.daySummary.todos == DaySummaryTodos(done: 0, left: 0))
    }

    @Test func noLineWhenTodosAreOff() async {
        let h = await harness(on: false)
        #expect(h.engine.daySummary.todos == nil)
    }

    @Test(arguments: [TodoAccess.denied, .notAsked])
    func noLineWithoutAccess(_ access: TodoAccess) async {
        let h = await harness(access: access)
        #expect(h.engine.daySummary.todos == nil)
    }

    @Test func leftTodosDoNotChangeTheAllMetVerdict() async {
        let met: (inout Persisted) -> Void = {
            $0.prefs.reading.enabled = false
            $0.prefs.water.dailyGoalGlasses = 6
            $0.events = [.done(.water, 6, at: day(2026, 3, 4, 8))]
        }
        let with = await harness(configure: met)
        let without = await harness(on: false, configure: met)
        #expect(with.engine.daySummary.todos?.left == 3)
        #expect(with.engine.daySummary.verdict == .allMet)
        #expect(with.engine.daySummary.verdict == without.engine.daySummary.verdict)
        #expect(with.engine.daySummary.rows == without.engine.daySummary.rows)
    }

    @Test func noTodosDoneDoesNotMakeANoneMetDayAllMet() async {
        let with = await harness()
        let without = await harness(on: false)
        #expect(with.engine.daySummary.verdict == .noneMet)
        #expect(without.engine.daySummary.verdict == .noneMet)
    }

    @Test func theLineText() {
        #expect(Copywriter.todoDaySummaryLine(done: 2, left: 3) == "To-dos: 2 done · 3 left for today")
        #expect(Copywriter.todoDaySummaryLine(done: 0, left: 0) == "To-dos: 0 done · 0 left for today")
    }

    @Test func theSummaryKeepsItsRowsWithATodosLine() {
        let rows = [DaySummaryRow(id: .water, status: .off, streak: 0)]
        let s = DaySummary(rows: rows, todos: DaySummaryTodos(done: 1, left: 0))
        #expect(s.rows == rows)
        #expect(s.todos?.done == 1)
        #expect(DaySummary(rows: rows).todos == nil)
        #expect(s.verdict == .restDay)
    }
}
