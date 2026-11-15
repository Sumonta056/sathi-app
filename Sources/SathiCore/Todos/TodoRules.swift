import Foundation

package enum TodoRules {
    package static func sorted(_ items: [Todo]) -> [Todo] {
        items.sorted { a, b in
            switch (a.due, b.due) {
            case let (x?, y?):
                if x.date != y.date { return x.date < y.date }
            case (.some, nil): return true
            case (nil, .some): return false
            case (nil, nil):
                if a.createdAt != b.createdAt { return a.createdAt > b.createdAt }
            }
            return a.title < b.title
        }
    }

    package static func sortedByDoneAt(_ items: [Todo]) -> [Todo] {
        items.sorted { a, b in
            let x = a.doneAt ?? .distantPast
            let y = b.doneAt ?? .distantPast
            if x != y { return x > y }
            return a.title < b.title
        }
    }

    package static func isDueToday(_ t: Todo, now: Date, calendar: Calendar) -> Bool {
        guard !t.isDone, let due = t.due else { return false }
        return calendar.startOfDay(for: due.date) <= calendar.startOfDay(for: now)
    }

    package static func isOverdue(_ t: Todo, now: Date, calendar: Calendar) -> Bool {
        guard !t.isDone, let due = t.due else { return false }
        if due.hasTime { return due.date < now }
        return calendar.startOfDay(for: due.date) < calendar.startOfDay(for: now)
    }

    package static func dueToday(_ items: [Todo], now: Date, calendar: Calendar) -> [Todo] {
        sorted(items.filter { isDueToday($0, now: now, calendar: calendar) })
    }

    package static func overdueCount(_ items: [Todo], now: Date, calendar: Calendar) -> Int {
        items.filter { isOverdue($0, now: now, calendar: calendar) }.count
    }

    package static func quickPanel(_ items: [Todo], now: Date, calendar: Calendar) -> [Todo] {
        Array(dueToday(items, now: now, calendar: calendar).prefix(Limits.todoQuickPanelMax))
    }

    package static func shown(_ items: [Todo], hiddenListIDs: Set<String>) -> [Todo] {
        items.filter { !hiddenListIDs.contains($0.listID) }
    }

    package static func completedSince(now: Date, calendar: Calendar) -> Date {
        let start = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: -(Limits.todoCompletedDays - 1), to: start) ?? start
    }

    package static func isRecentlyCompleted(_ t: Todo, now: Date, calendar: Calendar) -> Bool {
        guard t.isDone, let at = t.doneAt else { return false }
        return at >= completedSince(now: now, calendar: calendar)
    }

    package static func openCount(listID: String, in items: [Todo]) -> Int {
        items.filter { $0.listID == listID && !$0.isDone }.count
    }

    package static func defaultAccountID(accounts: [TodoAccount], preferred: String?) -> String? {
        let usable = accounts.filter(\.allowsNewLists)
        if let preferred, usable.contains(where: { $0.id == preferred }) { return preferred }
        if let icloud = usable.first(where: { $0.name == Limits.todoPreferredAccountName }) { return icloud.id }
        return usable.first?.id
    }
}
