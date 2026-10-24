import Foundation

package struct GoalText: Equatable, Sendable {
    package var done: String
    package var rest: String

    package init(done: String, rest: String) {
        self.done = done
        self.rest = rest
    }
}
