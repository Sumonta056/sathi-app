import Foundation

extension Engine {
    package var todosBadgeCount: Int {
        guard data.prefs.todos.isOn, todoAccess == .allowed else { return 0 }
        let n = clock.now
        return todoSnapshot.open.filter { TodoRules.isDueToday($0, now: n, calendar: calendar) }.count
    }
}
