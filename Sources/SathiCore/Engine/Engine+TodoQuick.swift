import Foundation

extension Engine {
    package var quickTodos: QuickTodos? {
        guard data.prefs.todos.isOn, todoAccess == .allowed else { return nil }
        let n = clock.now
        let due = TodoRules.dueToday(todoSnapshot.open, now: n, calendar: calendar)
        guard !due.isEmpty else { return nil }
        let rows = due.prefix(Limits.todoQuickPanelMax).map { t in
            QuickTodoRow(todo: t, isOverdue: TodoRules.isOverdue(t, now: n, calendar: calendar), timeText: quickTodoTime(t, now: n))
        }
        return QuickTodos(count: due.count, overdue: TodoRules.overdueCount(due, now: n, calendar: calendar), rows: Array(rows))
    }

    private func quickTodoTime(_ t: Todo, now n: Date) -> String {
        guard let due = t.due else { return "" }
        if !calendar.isDate(due.date, inSameDayAs: n) { return Copywriter.todoQuickEarlier }
        return due.hasTime ? Copywriter.trackerClock(due.date, calendar: calendar) : Copywriter.todoQuickToday
    }
}
