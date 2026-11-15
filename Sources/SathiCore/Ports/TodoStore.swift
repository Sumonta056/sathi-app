import Foundation

package enum TodoAccess: Equatable, Sendable { case notAsked, allowed, denied }

package enum TodoWriteResult: Equatable, Sendable { case done(id: String), missing, failed }

@MainActor
package protocol TodoStore: AnyObject {
    var access: TodoAccess { get }
    var revision: Int { get }
    func requestAccess() async -> TodoAccess
    func accounts() -> [TodoAccount]
    func lists() -> [TodoList]
    func todos(listIDs: Set<String>, completedSince: Date) async -> [Todo]
    func add(_ draft: TodoDraft) -> TodoWriteResult
    func update(_ id: String, _ edit: TodoEdit) -> TodoWriteResult
    func setDone(_ id: String, _ done: Bool) -> TodoWriteResult
    func move(_ id: String, to listID: String) -> TodoWriteResult
    func delete(_ id: String) -> TodoWriteResult
    func createList(_ draft: TodoListDraft) -> TodoWriteResult
    func renameList(_ id: String, to name: String) -> TodoWriteResult
}

@MainActor
package final class NoTodoStore: TodoStore {
    package nonisolated init() {}

    package var access: TodoAccess { .notAsked }
    package var revision: Int { 0 }
    package func requestAccess() async -> TodoAccess { .notAsked }
    package func accounts() -> [TodoAccount] { [] }
    package func lists() -> [TodoList] { [] }
    package func todos(listIDs: Set<String>, completedSince: Date) async -> [Todo] { [] }
    package func add(_ draft: TodoDraft) -> TodoWriteResult { .failed }
    package func update(_ id: String, _ edit: TodoEdit) -> TodoWriteResult { .failed }
    package func setDone(_ id: String, _ done: Bool) -> TodoWriteResult { .failed }
    package func move(_ id: String, to listID: String) -> TodoWriteResult { .failed }
    package func delete(_ id: String) -> TodoWriteResult { .failed }
    package func createList(_ draft: TodoListDraft) -> TodoWriteResult { .failed }
    package func renameList(_ id: String, to name: String) -> TodoWriteResult { .failed }
}
