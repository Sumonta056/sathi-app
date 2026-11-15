import Foundation

extension Engine {
    var todoDueAsks: Bool { data.prefs.todos.isOn && data.prefs.todos.askWhenDue && todoAccess == .allowed }

    func todoDueDeadlines(after n: Date) -> [Date] {
        guard todoDueAsks else { return [] }
        let hours = trackerHours
        return todoSnapshot.open.compactMap(Self.dueMoment).filter { $0 > n && hours.isInside($0) }
    }

    func tickTodoDue(_ n: Date) {
        if !data.prefs.todos.isOn, data.live.tracker.prompt?.kind == .todoDue { clearTrackerPrompt() }
        guard let from = todoDueCheckedUntil else {
            todoDueCheckedUntil = n
            return
        }
        let slot = todoDueSlot
        if todoDueAsks, slot == .hold { return }
        todoDueCheckedUntil = max(from, n)
        guard todoDueAsks, todoDueCanAsk(n) else { return }
        let due = todoSnapshot.open.filter { t in Self.dueMoment(t).map { $0 > from && $0 <= n } ?? false }
        guard !due.isEmpty else { return }
        switch slot {
        case .open: setTrackerPrompt(PromptState(kind: .todoDue, shownAt: n, askTime: n, todoIDs: TodoRules.sorted(due).map(\.id)))
        case .merge: mergeDueTodos(due)
        case .hold: break
        }
    }

    private enum TodoDueSlot { case open, merge, hold }

    private var todoDueSlot: TodoDueSlot {
        guard let p = data.live.tracker.prompt else { return .open }
        switch p.kind {
        case .whatNow: return p.switchFrom == nil && !trackerRuntime.promptByUser ? .open : .hold
        case .stillOnIt: return p.todoIDs.isEmpty ? .open : .hold
        case .todoDue: return .merge
        case .center, .welcomeBack, .eventAsk: return .hold
        }
    }

    private func todoDueCanAsk(_ n: Date) -> Bool {
        trackerHours.isInside(n) && data.live.tracker.awaySince == nil && !trackerIsBusy && !isAnyLockShowing
    }

    private func mergeDueTodos(_ due: [Todo]) {
        guard var p = data.live.tracker.prompt else { return }
        let ids = Set(p.todoIDs).union(due.map(\.id))
        p.todoIDs = TodoRules.sorted(todoSnapshot.open.filter { ids.contains($0.id) }).map(\.id)
        data.live.tracker.prompt = p
        reshowTrackerPrompt()
    }

    func reshowTrackerPrompt() {
        guard let k = data.live.tracker.prompt?.kind else { return }
        if trackerRuntime.shownPrompt == k { presenter.showTrackerPrompt(k) } else { presentTrackerPrompt() }
    }

    private static func dueMoment(_ t: Todo) -> Date? {
        guard !t.isDone, let due = t.due, due.hasTime else { return nil }
        return due.date.wholeMinute
    }
}
