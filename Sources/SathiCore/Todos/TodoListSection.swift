import Foundation

package struct TodoListSection: Equatable, Sendable {
    package var list: TodoList
    package var todos: [Todo]

    package init(list: TodoList, todos: [Todo]) {
        self.list = list
        self.todos = todos
    }
}

extension TodoRules {
    package static func listSections(lists: [TodoList], open: [Todo]) -> [TodoListSection] {
        lists.compactMap { list in
            let todos = open.filter { $0.listID == list.id }
            return todos.isEmpty ? nil : TodoListSection(list: list, todos: todos)
        }
    }
}
