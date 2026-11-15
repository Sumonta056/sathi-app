import Foundation

extension Engine {
    var todoDueAsks: Bool { data.prefs.todos.isOn && data.prefs.todos.askWhenDue && todoAccess == .allowed }

    func todoDueDeadlines(after n: Date) -> [Date] {
        guard todoDueAsks else { return [] }
        return todoSnapshot.open.compactMap(Self.dueMoment).filter { $0 > n }
    }

    func tickTodoDue(_ n: Date) {
        guard let from = todoDueCheckedUntil else {
            todoDueCheckedUntil = n
            return
        }
        todoDueCheckedUntil = max(from, n)
        guard todoDueAsks, canAskTodoDue(n) else { return }
        let due = todoSnapshot.open.filter { t in Self.dueMoment(t).map { $0 > from && $0 <= n } ?? false }
        guard !due.isEmpty else { return }
        let ids = TodoRules.sorted(due).map(\.id)
        setTrackerPrompt(PromptState(kind: .todoDue, shownAt: n, askTime: n, todoIDs: ids))
    }

    func withTodoDoneAsk(_ prompt: PromptState) -> PromptState {
        guard prompt.kind == .stillOnIt, data.prefs.todos.isOn, let r = data.live.tracker.running,
              let id = r.todoID, !r.askedTodoDone, todoSnapshot.open.contains(where: { $0.id == id }) else { return prompt }
        data.live.tracker.running?.askedTodoDone = true
        var p = prompt
        p.todoIDs = [id]
        return p
    }

    func fillTodos(_ s: inout TrackerPromptState, prompt p: PromptState) {
        guard data.prefs.todos.isOn, !p.todoIDs.isEmpty else { return }
        let open = todoSnapshot.open
        s.todoListNames = Dictionary(todoSnapshot.lists.map { ($0.id, $0.name) }, uniquingKeysWith: { a, _ in a })
        switch p.kind {
        case .todoDue: s.todos = TodoRules.sorted(open.filter { p.todoIDs.contains($0.id) })
        case .stillOnIt: s.todoDoneAsk = p.todoIDs.first.flatMap { id in open.first { $0.id == id } }
        case .whatNow, .center, .welcomeBack, .eventAsk: break
        }
        if let first = s.todos.first, s.draft.text.isEmpty { s.draft.text = first.title }
    }

    private func canAskTodoDue(_ n: Date) -> Bool {
        let t = data.live.tracker
        guard trackerHours.isInside(n), t.awaySince == nil, !trackerIsBusy, !isAnyLockShowing else { return false }
        guard let p = t.prompt else { return true }
        switch p.kind {
        case .whatNow: return p.switchFrom == nil && !trackerRuntime.promptByUser
        case .stillOnIt: return p.todoIDs.isEmpty
        case .center, .welcomeBack, .eventAsk, .todoDue: return false
        }
    }

    private static func dueMoment(_ t: Todo) -> Date? {
        guard !t.isDone, let due = t.due, due.hasTime else { return nil }
        return due.date.wholeMinute
    }
}
