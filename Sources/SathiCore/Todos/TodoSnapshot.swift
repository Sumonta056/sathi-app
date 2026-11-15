import Foundation

package struct TodoSnapshot: Equatable, Sendable {
    package var lists: [TodoList]
    package var open: [Todo]
    package var recentCompleted: [Todo]
    package var revision: Int

    package init(lists: [TodoList], open: [Todo], recentCompleted: [Todo], revision: Int) {
        self.lists = lists
        self.open = open
        self.recentCompleted = recentCompleted
        self.revision = revision
    }

    package static let empty = TodoSnapshot(lists: [], open: [], recentCompleted: [], revision: 0)

    package var todos: [Todo] { open + recentCompleted }
}
