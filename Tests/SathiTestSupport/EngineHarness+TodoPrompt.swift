import Foundation
import SathiCore

package func timedDue(_ hour: Int, _ minute: Int = 0, on dayOfMonth: Int = 4) -> TodoDue {
    TodoDue(date: day(2026, 3, dayOfMonth, hour, minute), hasTime: true)
}

package func dateOnlyDue(on dayOfMonth: Int = 4) -> TodoDue {
    TodoDue(date: day(2026, 3, dayOfMonth), hasTime: false)
}

extension EngineHarness {
    package static func todoTracker(
        at start: Date = day(2026, 3, 4, 10),
        todos: [Todo],
        lists: [TodoList] = [makeTodoList("inbox")],
        running: ActivityDraft? = ActivityDraft(text: "Code review", length: .minutes(120)),
        askWhenDue: Bool = true,
        trackerOn: Bool = true,
        configure: (inout Persisted) -> Void = { _ in }
    ) async -> EngineHarness {
        let h = EngineHarness.tracker(at: start) {
            $0.prefs.todos.isOn = true
            $0.prefs.todos.askWhenDue = askWhenDue
            $0.prefs.tracker.isOn = trackerOn
            configure(&$0)
        }
        h.todos.listsValue = lists
        h.todos.todosValue = todos
        h.engine.start()
        await h.engine.refreshTodosNow()
        if let running { h.engine.startActivity(running) }
        return h
    }

    package func replaceTodos(_ items: [Todo]) async {
        todos.todosValue = items
        todos.revision += 1
        calendarChanges.fire()
        await engine.refreshTodosNow()
    }
}
