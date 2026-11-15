import Foundation

extension Engine {
    @discardableResult
    package func addTodo(_ d: TodoDraft) async -> TodoWriteResult {
        guard canWriteTodos, d.isValid, isEditableTodoList(d.listID) else { return .failed }
        var draft = d
        draft.title = d.trimmedTitle
        return await afterTodoWrite(todos.add(draft))
    }

    @discardableResult
    package func editTodo(_ id: String, _ e: TodoEdit) async -> TodoWriteResult {
        let title = e.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canWriteTodos, !title.isEmpty, isEditableTodo(id) else { return .failed }
        var edit = e
        edit.title = title
        return await afterTodoWrite(todos.update(id, edit))
    }

    @discardableResult
    package func setTodoDone(_ id: String, _ done: Bool) async -> TodoWriteResult {
        guard canWriteTodos, isEditableTodo(id) else { return .failed }
        return await afterTodoWrite(todos.setDone(id, done))
    }

    @discardableResult
    package func moveTodo(_ id: String, to listID: String) async -> TodoWriteResult {
        guard canWriteTodos, isEditableTodo(id), isEditableTodoList(listID) else { return .failed }
        return await afterTodoWrite(todos.move(id, to: listID))
    }

    @discardableResult
    package func deleteTodo(_ id: String) async -> TodoWriteResult {
        guard canWriteTodos, isEditableTodo(id) else { return .failed }
        return await afterTodoWrite(todos.delete(id))
    }

    @discardableResult
    package func saveTodo(_ t: Todo, _ f: TodoEditForm) async -> TodoSaveResult {
        guard f.isValid else { return .failed }
        let moves = f.listID != t.listID
        guard canWriteTodos, isEditableTodo(t.id), !moves || isEditableTodoList(f.listID) else { return .failed }
        let updated = todos.update(t.id, f.edit(calendar: calendar))
        var result = TodoSaveResult.failed
        if case .done = updated {
            if moves, case .done = todos.move(t.id, to: f.listID) {
                result = .saved
            } else {
                result = moves ? .partlySaved : .saved
            }
        }
        _ = await afterTodoWrite(updated)
        return result
    }

    @discardableResult
    package func createTodoList(_ d: TodoListDraft) async -> TodoWriteResult {
        guard canWriteTodos, d.isValid else { return .failed }
        var draft = d
        draft.name = d.trimmedName
        return await afterTodoWrite(todos.createList(draft))
    }

    @discardableResult
    package func renameTodoList(_ id: String, to name: String) async -> TodoWriteResult {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canWriteTodos, !trimmed.isEmpty, isEditableTodoList(id) else { return .failed }
        return await afterTodoWrite(todos.renameList(id, to: trimmed))
    }

    private var canWriteTodos: Bool { data.prefs.todos.isOn && todos.access == .allowed }

    private func isEditableTodoList(_ id: String) -> Bool {
        todos.lists().contains { $0.id == id && $0.canEdit }
    }

    private func isEditableTodo(_ id: String) -> Bool {
        guard let t = todoSnapshot.todos.first(where: { $0.id == id }) else { return false }
        return isEditableTodoList(t.listID)
    }

    private func afterTodoWrite(_ result: TodoWriteResult) async -> TodoWriteResult {
        todoRuntime.stale = true
        await refreshTodosNow()
        return result
    }
}
