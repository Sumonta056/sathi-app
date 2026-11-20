import Foundation

package enum TodoListOrder {
    package static func ordered(_ lists: [TodoList], order: [String]) -> [TodoList] {
        var accounts: [String] = []
        for list in lists where !accounts.contains(list.accountID) {
            accounts.append(list.accountID)
        }
        return accounts.flatMap { account in
            placed(lists.filter { $0.accountID == account }, order: order)
        }
    }

    package static func moved(all: [TodoList], order: [String], id: String, before: String?) -> [String]? {
        guard !all.isEmpty, let account = all.first(where: { $0.id == id })?.accountID else { return nil }
        if let before, all.first(where: { $0.id == before })?.accountID != account { return nil }
        let full = ordered(all, order: order)
        let group = full.filter { $0.accountID == account }.map(\.id)
        guard let next = TodoRules.moved(group, id: id, before: before) else { return nil }
        var queue = next[...]
        return full.map { list in
            guard list.accountID == account, let head = queue.popFirst() else { return list.id }
            return head
        }
    }

    private static func placed(_ group: [TodoList], order: [String]) -> [TodoList] {
        var seen = Set<String>()
        let unique = order.filter { seen.insert($0).inserted }
        let byID = Dictionary(group.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        return unique.compactMap { byID[$0] } + group.filter { !seen.contains($0.id) }
    }
}
