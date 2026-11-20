import Foundation

extension Engine {
    package func setTodoBoardColumns(_ choice: TodoBoardColumnChoice) {
        data.prefs.todos.boardColumns = choice
    }

    package func moveTodoBoard(_ id: String, column: Int, before: String?, shown: [[String]]) {
        guard let count = data.prefs.todos.boardColumns.count else { return }
        let key = String(count)
        guard let next = TodoBoardColumnLayout.moved(
            shown: shown, id: id, column: column, before: before, count: count
        ) else { return }
        let saved = data.prefs.todos.boardLayouts[key] ?? []
        let known = Set(todoPageAllLists.map(\.id))
        data.prefs.todos.boardLayouts[key] = TodoBoardColumnLayout.kept(next, saved: saved, known: known)
    }
}
