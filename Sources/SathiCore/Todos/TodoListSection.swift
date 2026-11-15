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
    package static func sideOrder(_ lists: [TodoList]) -> [TodoList] {
        var accounts: [String] = []
        for list in lists where !accounts.contains(list.accountName) {
            accounts.append(list.accountName)
        }
        return accounts.flatMap { name in lists.filter { $0.accountName == name } }
    }

    package static func listSections(lists: [TodoList], open: [Todo]) -> [TodoListSection] {
        sideOrder(lists).compactMap { list in
            let todos = open.filter { $0.listID == list.id }
            return todos.isEmpty ? nil : TodoListSection(list: list, todos: todos)
        }
    }
}
