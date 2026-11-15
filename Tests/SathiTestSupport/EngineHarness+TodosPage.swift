import Foundation
import SathiCore

package let todoRemindersPrivacyURL = "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders"

@MainActor
package func waitUntil(_ condition: () -> Bool) async {
    var spins = 0
    while !condition(), spins < 2000 {
        await Task.yield()
        spins += 1
    }
}

package func makeReadOnlyTodoList(_ id: String, _ name: String = "Shared") -> TodoList {
    TodoList(id: id, name: name, colorHex: "#8E8E93", accountID: "exchange", accountName: "Exchange", canEdit: false)
}

extension EngineHarness {
    package static func todosReady(
        lists: [TodoList] = [makeTodoList("inbox", "Inbox"), makeTodoList("work", "Work")],
        items: [Todo] = [],
        access: TodoAccess = .allowed,
        on: Bool = true,
        configure: @escaping (inout Persisted) -> Void = { _ in }
    ) async -> EngineHarness {
        let h = EngineHarness {
            $0.prefs.todos.isOn = on
            configure(&$0)
        }
        h.todos.listsValue = lists
        h.todos.todosValue = items
        h.todos.access = access
        await h.engine.refreshTodosNow()
        return h
    }

    package static func pageFixture() async -> EngineHarness {
        let lists = [makeTodoList("inbox", "Inbox"), makeTodoList("work", "Work"), makeReadOnlyTodoList("ro")]
        return await todosReady(lists: lists, items: pageItems)
    }

    package static var pageItems: [Todo] {
        let created = day(2026, 3, 1)
        return [
            makeTodo("a", "Alpha", list: "inbox", due: TodoDue(date: day(2026, 3, 4), hasTime: false)),
            makeTodo("b", "Bravo", list: "work", due: TodoDue(date: day(2026, 3, 4, 14), hasTime: true)),
            makeTodo("c", "Charlie", list: "inbox", created: created),
            makeTodo("d", "Delta", list: "work", due: TodoDue(date: day(2026, 3, 10, 9), hasTime: true)),
            makeTodo("e", "Echo", list: "ro"),
            makeTodo("f", "Foxtrot", list: "inbox", due: TodoDue(date: day(2026, 3, 2, 9), hasTime: true)),
            makeTodo("g", "Golf", list: "inbox", done: true, doneAt: day(2026, 3, 3, 12)),
            makeTodo("h", "Hotel", list: "work", done: true, doneAt: day(2026, 3, 2, 12))
        ]
    }
}
