import Foundation

extension Engine {
    package func moveTodo(_ id: String, before: String?) {
        guard let listID = todoSnapshot.open.first(where: { $0.id == id })?.listID else { return }
        let ids = todoShownOpen(listID).map(\.id)
        guard let next = TodoRules.moved(ids, id: id, before: before) else { return }
        var order = data.prefs.todos.order
        order[listID] = next
        data.prefs.todos.order = TodoRules.pruned(order, listIDs: Set(todoPageAllLists.map(\.id)))
    }

    package func todoSideLists(_ selection: TodoSelection) -> [TodoList] {
        TodoRules.sideLists(todoSnapshot.lists, open: todoSnapshot.open, selected: selection)
    }

    func todoShownOpen(_ listID: String) -> [Todo] {
        TodoRules.ordered(todoSnapshot.open.filter { $0.listID == listID }, order: data.prefs.todos.order[listID] ?? [])
    }
}

extension Engine {
    func todoOrderedSections(_ sections: [TodoListSection]) -> [TodoListSection] {
        sections.map { s in
            TodoListSection(list: s.list, todos: TodoRules.ordered(s.todos, order: data.prefs.todos.order[s.list.id] ?? []))
        }
    }
}
