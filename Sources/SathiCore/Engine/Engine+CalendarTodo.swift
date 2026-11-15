import Foundation

extension Engine {
    func calendarTodoBlocks(_ range: CalendarPageRange) -> [CalendarBlock] {
        let hidden = data.prefs.calendarPage.hiddenCalendarIDs
        let lists = todoSnapshot.lists.filter { !hidden.contains($0.id) }
        let shown = Set(lists.map(\.id))
        return CalendarBlockBuilder.todoBlocks(
            todoSnapshot.open.filter { shown.contains($0.listID) },
            colors: Dictionary(lists.map { ($0.id, TodoRules.colorValue($0.colorHex)) }) { first, _ in first },
            interval: range.interval,
            calendar: calendar
        )
    }

    func todoShownGroups() -> [ShownCalendarGroup] {
        guard data.prefs.todos.isOn, !todoSnapshot.lists.isEmpty else { return [] }
        let hidden = data.prefs.calendarPage.hiddenCalendarIDs
        let rows = todoSnapshot.lists.map { list in
            ShownCalendar(
                choice: CalendarChoice(
                    id: list.id, title: list.name, account: Copywriter.calendarTodoLists,
                    colorHex: TodoRules.colorValue(list.colorHex)
                ),
                isShown: !hidden.contains(list.id)
            )
        }
        return [ShownCalendarGroup(account: Copywriter.calendarTodoLists, calendars: rows)]
    }

    package func completeCalendarTodo(_ id: String) {
        _ = todos.setDone(id, true)
        todoRuntime.stale = true
        refreshTodos()
    }
}
