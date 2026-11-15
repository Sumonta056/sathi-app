import Foundation

extension Engine {
    var todosWantChanges: Bool { isRunning && data.prefs.todos.isOn }

    package func refreshTodos() {
        todoRuntime.refreshTask = Task { @MainActor [weak self] in
            await self?.refreshTodosNow()
        }
    }

    package func refreshTodosNow() async {
        let prefs = data.prefs.todos
        guard prefs.isOn else {
            todoRuntime.token += 1
            applyTodos(.empty)
            return
        }
        let access = todos.access
        let since = TodoRules.completedSince(now: clock.now, calendar: calendar)
        let unchanged = todoRuntime.loadedSince == since && todoRuntime.loadedRevision == todos.revision
        if access == todoAccess, !todoRuntime.stale, unchanged { return }
        todoRuntime.stale = false
        todoRuntime.token += 1
        let token = todoRuntime.token
        todoAccess = access
        todoRuntime.loadedSince = since
        todoRuntime.loadedRevision = todos.revision
        guard access == .allowed else {
            todoPageAllLists = []
            applyTodos(.empty)
            return
        }
        let all = todos.lists()
        todoPageAllLists = all
        let lists = all.filter { !prefs.hiddenListIDs.contains($0.id) }
        let items = await todos.todos(listIDs: Set(lists.map(\.id)), completedSince: since)
        guard token == todoRuntime.token else { return }
        applyTodos(Self.todoSnapshot(lists: lists, items: items, revision: todos.revision))
    }

    func todosPrefsChanged(from old: TodoPrefs) {
        let new = data.prefs.todos
        syncCalendarChangeListener()
        if !new.isOn {
            todoRuntime.stale = true
            todoRuntime.token += 1
            todoRuntime.loadedRevision = nil
            todoAccess = .notAsked
            todoPageAllLists = []
            applyTodos(.empty)
        } else if old.isOn != new.isOn || old.hiddenListIDs != new.hiddenListIDs {
            todoRuntime.stale = true
            if isRunning { refreshTodos() }
        }
    }

    func stopTodos() {
        todoRuntime.refreshTask?.cancel()
        todoRuntime.refreshTask = nil
        todoRuntime.token += 1
        todoRuntime.stale = true
    }

    func todosStoreChanged() {
        guard data.prefs.todos.isOn else { return }
        todoRuntime.stale = true
        refreshTodos()
    }

    func startTodos() {
        if data.prefs.todos.isOn { refreshTodos() }
    }

    func applyTodos(_ next: TodoSnapshot) {
        let cur = todoSnapshot
        if cur.lists == next.lists, cur.open == next.open, cur.recentCompleted == next.recentCompleted { return }
        todoSnapshot = next
    }

    private static func todoSnapshot(lists: [TodoList], items: [Todo], revision: Int) -> TodoSnapshot {
        TodoSnapshot(
            lists: lists,
            open: TodoRules.sorted(items.filter { !$0.isDone }),
            recentCompleted: TodoRules.sortedByDoneAt(items.filter(\.isDone)),
            revision: revision
        )
    }
}
