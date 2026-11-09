import Foundation

package struct ActivityMonth: Equatable, Sendable {
    package var key: MonthKey
    package var items: [Activity]

    package init(key: MonthKey, items: [Activity]) {
        self.key = key
        self.items = items
    }
}
