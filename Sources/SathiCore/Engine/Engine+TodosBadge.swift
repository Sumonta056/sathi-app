import Foundation

extension Engine {
    package var todosBadgeCount: Int {
        guard data.prefs.todos.isOn, todoAccess == .allowed else { return 0 }
        return TodoRules.dueToday(todoSnapshot.open, now: clock.now, calendar: calendar).count
    }
}
