import Foundation

package enum TodoSmartList: String, CaseIterable, Sendable {
    case today, scheduled, all, completed

    package func matches(_ todo: Todo, now: Date, calendar: Calendar) -> Bool {
        switch self {
        case .today: TodoRules.isDueToday(todo, now: now, calendar: calendar)
        case .scheduled: !todo.isDone && todo.due != nil
        case .all: !todo.isDone
        case .completed: TodoRules.isRecentlyCompleted(todo, now: now, calendar: calendar)
        }
    }

    package func todos(in items: [Todo], now: Date, calendar: Calendar) -> [Todo] {
        let hits = items.filter { matches($0, now: now, calendar: calendar) }
        if self == .completed {
            return TodoRules.sortedByDoneAt(hits)
        }
        return TodoRules.sorted(hits)
    }

    package func count(in items: [Todo], now: Date, calendar: Calendar) -> Int {
        items.filter { matches($0, now: now, calendar: calendar) }.count
    }
}
