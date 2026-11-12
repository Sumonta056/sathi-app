import Foundation
import SathiCore

package final class InMemoryActivityStore: ActivityStore, @unchecked Sendable {
    package private(set) var months: [MonthKey: ActivityMonth] = [:]
    package private(set) var saves = 0
    package private(set) var reads: [MonthKey] = []
    package private(set) var flushes = 0
    package private(set) var backups: [MonthKey: ActivityMonth] = [:]
    package var failFlush = false
    package var failBackup = false

    package init(activities: [Activity] = [], calendar: Calendar = .current) {
        for item in activities {
            let key = MonthKey(item.start, calendar: calendar)
            months[key, default: ActivityMonth(key: key, items: [])].items.append(item)
        }
    }

    package var all: [Activity] { allActivities() }

    package func month(_ key: MonthKey) -> ActivityMonth {
        reads.append(key)
        return months[key] ?? ActivityMonth(key: key, items: [])
    }

    package func save(_ month: ActivityMonth) {
        months[month.key] = month
        saves += 1
    }

    package func savedMonths() -> [MonthKey] {
        months.values.filter { !$0.items.isEmpty }.map(\.key).sorted()
    }

    @discardableResult
    package func backup(_ key: MonthKey) -> Bool {
        guard !failBackup else { return false }
        if backups[key] == nil { backups[key] = months[key] ?? ActivityMonth(key: key, items: []) }
        return true
    }

    @discardableResult
    package func flush() -> Bool {
        flushes += 1
        return !failFlush
    }
}
