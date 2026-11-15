import Foundation
import SathiCore

extension EngineHarness {
    package static func withCalendarTodos(
        at start: Date = day(2026, 3, 4, 12),
        lists: [TodoList],
        todos: [Todo],
        todosOn: Bool = true,
        hiddenCalendarIDs: Set<String> = [],
        configure: (inout Persisted) -> Void = { _ in }
    ) -> EngineHarness {
        let h = EngineHarness(at: start) {
            $0.prefs.todos.isOn = todosOn
            $0.prefs.calendarPage.hiddenCalendarIDs = hiddenCalendarIDs
            configure(&$0)
        }
        h.todos.listsValue = lists
        h.todos.todosValue = todos
        return h
    }

    package func loadTodos() async {
        await engine.refreshTodosNow()
    }

    package func calendarDay(_ y: Int = 2026, _ m: Int = 3, _ d: Int = 4) -> CalendarPageRange {
        .containing(day(y, m, d, 12), kind: .day, calendar: engine.calendar)
    }
}
