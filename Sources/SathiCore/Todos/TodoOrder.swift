import Foundation

extension TodoRules {
    package static func ordered(_ todos: [Todo], order: [String]) -> [Todo] {
        guard !order.isEmpty else { return todos }
        let byID = Dictionary(todos.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        var seen = Set<String>()
        let unique = order.filter { seen.insert($0).inserted }
        return todos.filter { !seen.contains($0.id) } + unique.compactMap { byID[$0] }
    }

    package static func pruned(_ order: [String: [String]], listIDs: Set<String>) -> [String: [String]] {
        guard !listIDs.isEmpty else { return order }
        return order.filter { listIDs.contains($0.key) }
    }

    package static func moved(_ ids: [String], id: String, before: String?) -> [String]? {
        guard id != before, ids.contains(id) else { return nil }
        if let before, !ids.contains(before) { return nil }
        var out = ids.filter { $0 != id }
        let at = before.flatMap { out.firstIndex(of: $0) } ?? out.endIndex
        out.insert(id, at: at)
        return out
    }

    package static func sideLists(_ lists: [TodoList], open: [Todo], selected: TodoSelection) -> [TodoList] {
        let used = Set(open.filter { !$0.isDone }.map(\.listID))
        return lists.filter { used.contains($0.id) || selected == .list($0.id) }
    }
}
