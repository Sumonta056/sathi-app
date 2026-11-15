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
        if let p = data.live.tracker.prompt, p.kind == .todoDue, p.todoIDs.contains(id) { closeTrackerPrompt() }
    }

    package func markTodoDone(_ yes: Bool) {
        guard let p = data.live.tracker.prompt, p.kind == .stillOnIt, let id = p.todoIDs.first else { return }
        if yes, data.prefs.todos.isOn {
            _ = todos.setDone(id, true)
            todoRuntime.stale = true
            refreshTodos()
        }
        data.live.tracker.prompt?.todoIDs = []
        if trackerRuntime.shownPrompt == .stillOnIt { presenter.showTrackerPrompt(.stillOnIt) }
    }
}
