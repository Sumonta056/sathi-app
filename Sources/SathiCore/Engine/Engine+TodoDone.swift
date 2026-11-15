import Foundation

extension Engine {
    @discardableResult
    package func startTodo(_ id: String, draft: ActivityDraft, switchAt: Date? = nil) -> Bool {
        guard startActivity(draft, switchAt: switchAt) else { return false }
        data.live.tracker.running?.todoID = id
        return true
    }

    package func doneTodo(_ id: String) {
        guard data.prefs.todos.isOn else { return }
        _ = todos.setDone(id, true)
        todoRuntime.stale = true
        refreshTodos()
        guard var p = data.live.tracker.prompt, p.kind == .todoDue, p.todoIDs.contains(id) else { return }
        p.todoIDs.removeAll { $0 == id }
        guard !p.todoIDs.isEmpty else { return closeTrackerPrompt() }
        data.live.tracker.prompt = p
        reshowTrackerPrompt()
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
