import Foundation

extension Engine {
    package var todoDefaultAccountID: String? {
        TodoRules.defaultAccountID(accounts: todos.accounts(), preferred: data.prefs.todos.newListAccountID)
    }

    package func todoPage(_ s: TodoSelection) -> TodoPageModel {
        let snap = todoSnapshot
        switch s {
        case let .smart(smart):
            let target = smart == .completed ? nil : todoOrderedLists.first(where: \.canEdit)?.id
            let today = TodoDue(date: calendar.startOfDay(for: clock.now), hasTime: false)
            let open = smart.todos(in: snap.todos, now: clock.now, calendar: calendar)
            return TodoPageModel(
                selection: s,
                title: Copywriter.todoSmartListName(smart),
                open: open,
                completed: [],
                targetListID: target,
                defaultDue: smart == .today || smart == .scheduled ? today : nil,
                sections: smart == .all ? todoOrderedSections(TodoRules.listSections(lists: todoOrderedLists, open: open)) : []
            )
        case let .list(id):
            guard let list = snap.lists.first(where: { $0.id == id }) else {
                return TodoPageModel(selection: s, title: "", open: [], completed: [], targetListID: nil)
            }
            return TodoPageModel(
                selection: s,
                title: list.name,
                open: todoShownOpen(id),
                completed: snap.recentCompleted.filter { $0.listID == id },
                targetListID: list.canEdit ? id : nil
            )
        }
    }

    package func todoCount(_ s: TodoSelection) -> Int {
        let snap = todoSnapshot
        switch s {
        case let .smart(smart): return smart.count(in: snap.todos, now: clock.now, calendar: calendar)
        case let .list(id): return TodoRules.openCount(listID: id, in: snap.open)
        }
    }

    package func todoAllLists() -> [TodoList] {
        guard data.prefs.todos.isOn, todoAccess == .allowed else { return [] }
        return TodoListOrder.ordered(todoPageAllLists, order: data.prefs.todos.listOrder)
    }

    package func setTodoListShown(_ id: String, _ shown: Bool) {
        if shown {
            data.prefs.todos.hiddenListIDs.remove(id)
        } else {
            data.prefs.todos.hiddenListIDs.insert(id)
        }
    }
}
