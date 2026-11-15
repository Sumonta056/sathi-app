import Foundation

package struct QuickTodoRow: Equatable, Sendable {
    package var todo: Todo
    package var isOverdue: Bool
    package var timeText: String
}

package struct QuickTodos: Equatable, Sendable {
    package var count: Int
    package var overdue: Int
    package var rows: [QuickTodoRow]
}
