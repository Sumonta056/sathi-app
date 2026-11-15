import Foundation

package struct TodoDue: Equatable, Sendable {
    package var date: Date
    package var hasTime: Bool

    package init(date: Date, hasTime: Bool) {
        self.date = date
        self.hasTime = hasTime
    }
}
