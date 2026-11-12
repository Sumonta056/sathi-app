import Foundation

package protocol ActivityStore: AnyObject, Sendable {
    func month(_ key: MonthKey) -> ActivityMonth
    func save(_ month: ActivityMonth)
    func savedMonths() -> [MonthKey]
    @discardableResult
    func backup(_ key: MonthKey) -> Bool
    @discardableResult
    func flush() -> Bool
}

extension ActivityStore {
    package func allActivities() -> [Activity] {
        savedMonths().sorted().flatMap { month($0).items }
    }
}

package final class NoActivityStore: ActivityStore {
    package init() {}

    package func month(_ key: MonthKey) -> ActivityMonth { ActivityMonth(key: key, items: []) }
    package func save(_ month: ActivityMonth) {}
    package func savedMonths() -> [MonthKey] { [] }
    @discardableResult
    package func backup(_ key: MonthKey) -> Bool { false }
    @discardableResult
    package func flush() -> Bool { true }
}
