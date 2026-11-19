import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine to-dos badge")
struct EngineTodosBadgeTests {
    private func items() -> [Todo] {
        [
            makeTodo("past", list: "inbox", due: timedDue(9)),
            makeTodo("later", list: "inbox", due: timedDue(23)),
            makeTodo("today", list: "work", due: dateOnlyDue()),
            makeTodo("overdue", list: "work", due: dateOnlyDue(on: 2)),
            makeTodo("future", list: "inbox", due: dateOnlyDue(on: 5)),
            makeTodo("nodate", list: "inbox"),
            makeTodo("done", list: "inbox", due: timedDue(8), done: true, doneAt: day(2026, 3, 4, 8, 30))
        ]
    }

    private func harness(
        on: Bool = true,
        access: TodoAccess = .allowed,
        hidden: Set<String> = [],
        items: [Todo]? = nil
    ) async -> EngineHarness {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) {
            $0.prefs.todos.isOn = on
            $0.prefs.todos.hiddenListIDs = hidden
        }
        h.todos.access = access
        h.todos.listsValue = [makeTodoList("inbox", "Inbox"), makeTodoList("work", "Work")]
        h.todos.todosValue = items ?? self.items()
        await h.engine.refreshTodosNow()
        return h
    }

    @Test func countsDueTodayAndOverdue() async {
        let h = await harness()
        #expect(h.engine.todosBadgeCount == 4)
    }

    @Test func countIsNotCutToTheQuickPanelRows() async {
        let h = await harness()
        #expect(h.engine.todosBadgeCount > Limits.todoQuickPanelMax)
    }

    @Test func zeroWhenTodosIsOff() async {
        let h = await harness(on: false)
        #expect(h.engine.todosBadgeCount == 0)
    }

    @Test(arguments: [TodoAccess.denied, .notAsked])
    func zeroWithoutAccess(_ access: TodoAccess) async {
        let h = await harness(access: access)
        #expect(h.engine.todosBadgeCount == 0)
    }

    @Test func aHiddenListDoesNotCount() async {
        let h = await harness(hidden: ["work"])
        #expect(h.engine.todosBadgeCount == 2)
    }

    @Test func zeroWhenNothingIsDueToday() async {
        let h = await harness(items: [makeTodo("future", due: dateOnlyDue(on: 5)), makeTodo("nodate")])
        #expect(h.engine.todosBadgeCount == 0)
    }

    @Test func aTodoMarkedDoneLeavesTheCount() async {
        var list = items()
        list[0] = makeTodo("past", list: "inbox", due: timedDue(9), done: true, doneAt: day(2026, 3, 4, 9, 30))
        let h = await harness(items: list)
        #expect(h.engine.todosBadgeCount == 3)
    }
}
