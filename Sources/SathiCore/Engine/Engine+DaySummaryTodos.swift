import Foundation

extension Engine {
    func summaryTodos(on day: Date) -> DaySummaryTodos? {
        guard data.prefs.todos.isOn, todoAccess == .allowed else { return nil }
        let s = todoSnapshot
        let done = s.recentCompleted.filter { $0.doneAt.map { calendar.isDate($0, inSameDayAs: day) } ?? false }.count
        let left = TodoRules.dueToday(s.open, now: day, calendar: calendar).count
        return DaySummaryTodos(done: done, left: left)
    }
}
