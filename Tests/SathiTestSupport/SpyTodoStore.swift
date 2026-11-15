import Foundation
import SathiCore

package enum TodoWriteCall: Equatable, Sendable {
    case added(TodoDraft)
    case updated(String, TodoEdit)
    case doneSet(String, Bool)
    case moved(String, String)
    case deleted(String)
    case listCreated(TodoListDraft)
    case listRenamed(String, String)
}

@MainActor
package final class SpyTodoStore: TodoStore {
    package var access: TodoAccess = .allowed
    package var accessAfterRequest: TodoAccess?
    package var accountsValue: [TodoAccount] = [
        TodoAccount(id: "icloud", name: "iCloud", allowsNewLists: true)
    ]
    package var listsValue: [TodoList] = []
    package var todosValue: [Todo] = []
    package var revision = 0
    package var nextResult: TodoWriteResult = .done(id: "new")
    package private(set) var requestCount = 0
    package private(set) var calls: [TodoWriteCall] = []
    package private(set) var readRequests: [Set<String>] = []
    package private(set) var completedSinceRequests: [Date] = []
    package var holdsReads = false
    private var waiting: [CheckedContinuation<Void, Never>] = []

    package var suspendedReads: Int { waiting.count }

    package func releaseReads() {
        let pending = waiting
        waiting = []
        for c in pending {
            c.resume()
        }
    }

    package init() {}

    package func requestAccess() async -> TodoAccess {
        requestCount += 1
        if let after = accessAfterRequest { access = after }
        return access
    }

    package func accounts() -> [TodoAccount] { accountsValue }

    package func lists() -> [TodoList] { listsValue }

    package func todos(listIDs: Set<String>, completedSince: Date) async -> [Todo] {
        readRequests.append(listIDs)
        completedSinceRequests.append(completedSince)
        let result = todosValue.filter { item in
            guard listIDs.contains(item.listID) else { return false }
            guard item.isDone else { return true }
            return (item.doneAt ?? .distantPast) >= completedSince
        }
        if holdsReads {
            await withCheckedContinuation { waiting.append($0) }
        }
        return result
    }

    package func add(_ draft: TodoDraft) -> TodoWriteResult {
        calls.append(.added(draft))
        return nextResult
    }

    package func update(_ id: String, _ edit: TodoEdit) -> TodoWriteResult {
        calls.append(.updated(id, edit))
        return nextResult
    }

    package func setDone(_ id: String, _ done: Bool) -> TodoWriteResult {
        calls.append(.doneSet(id, done))
        return nextResult
    }

    package func move(_ id: String, to listID: String) -> TodoWriteResult {
        calls.append(.moved(id, listID))
        return nextResult
    }

    package func delete(_ id: String) -> TodoWriteResult {
        calls.append(.deleted(id))
        return nextResult
    }

    package func createList(_ draft: TodoListDraft) -> TodoWriteResult {
        calls.append(.listCreated(draft))
        return nextResult
    }

    package func renameList(_ id: String, to name: String) -> TodoWriteResult {
        calls.append(.listRenamed(id, name))
        return nextResult
    }
}
