import Foundation

extension Engine {
    var todosReady: Bool { !data.prefs.todos.isOn || todoDueReady }

    func withTodoDoneAsk(_ prompt: PromptState) -> PromptState {
        guard prompt.kind != .todoDue, prompt.todoIDs.isEmpty, data.prefs.todos.isOn else { return prompt }
        let t = data.live.tracker
        let runningAsk = t.running.flatMap { r in
            !r.askedTodoDone && (prompt.kind == .stillOnIt || prompt.doneAt != nil) ? r.todoID : nil
        }
        guard let id = t.pendingTodoAsk ?? runningAsk else { return prompt }
        guard todosReady else {
            var p = prompt
            p.todoIDs = [id]
            return p
        }
        consumeTodoAsk(id)
        guard isOpenTodo(id) else { return prompt }
        var p = prompt
        p.todoIDs = [id]
        return p
    }

    func todosRead() {
        todoDueReady = true
        guard var p = data.live.tracker.prompt, !p.todoIDs.isEmpty else { return }
        if p.kind == .todoDue {
            p.todoIDs = p.todoIDs.filter(isOpenTodo)
            if p.todoIDs.isEmpty { return closeTrackerPrompt() }
        } else if let id = p.todoIDs.first {
            consumeTodoAsk(id)
            if !isOpenTodo(id) { p.todoIDs = [] }
        }
        data.live.tracker.prompt = p
        reshowTrackerPrompt()
    }

    func fillTodos(_ s: inout TrackerPromptState, prompt p: PromptState) {
        guard data.prefs.todos.isOn, !p.todoIDs.isEmpty else { return }
        let open = todoSnapshot.open
        s.todoListNames = Dictionary(todoSnapshot.lists.map { ($0.id, $0.name) }, uniquingKeysWith: { a, _ in a })
        if p.kind == .todoDue {
            s.todos = TodoRules.sorted(open.filter { p.todoIDs.contains($0.id) })
        } else {
            s.todoDoneAsk = p.todoIDs.first.flatMap { id in open.first { $0.id == id } }
        }
        if let first = s.todos.first, s.draft.text.isEmpty { s.draft.text = first.title }
    }

    private func consumeTodoAsk(_ id: String) {
        if data.live.tracker.pendingTodoAsk == id { data.live.tracker.pendingTodoAsk = nil }
        if data.live.tracker.running?.todoID == id { data.live.tracker.running?.askedTodoDone = true }
    }

    private func isOpenTodo(_ id: String) -> Bool {
        data.prefs.todos.isOn && todoSnapshot.open.contains { $0.id == id }
    }
}
