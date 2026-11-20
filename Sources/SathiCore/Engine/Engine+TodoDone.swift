import Foundation

extension Engine {
    @discardableResult
    package func startTodo(_ id: String, draft: ActivityDraft, switchAt: Date? = nil) -> Bool {
        guard startActivity(draft, switchAt: switchAt) else { return false }
        data.live.tracker.running?.todoID = id
        return true
    }

    @discardableResult
    package func doneTodo(_ id: String) -> Bool {
        guard data.prefs.todos.isOn else { return false }
        let result = todos.setDone(id, true)
        todoRuntime.stale = true
        refreshTodos()
        let ok = result != .failed
        guard var p = data.live.tracker.prompt, p.kind == .todoDue, p.todoIDs.contains(id) else { return ok }
        p.todoIDs.removeAll { $0 == id }
        guard !p.todoIDs.isEmpty else {
            closeTrackerPrompt()
            return ok
        }
        data.live.tracker.prompt = p
        reshowTrackerPrompt()
        return ok
    }

    package func markTodoDone(_ yes: Bool) {
        guard let p = data.live.tracker.prompt, p.kind != .todoDue, let id = p.todoIDs.first else { return }
        if yes, data.prefs.todos.isOn {
            _ = todos.setDone(id, true)
            todoRuntime.stale = true
            refreshTodos()
        }
        data.live.tracker.prompt?.todoIDs = []
        reshowTrackerPrompt()
    }
}
