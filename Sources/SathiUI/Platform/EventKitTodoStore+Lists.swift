import AppKit
import EventKit
import SathiCore

extension EventKitTodoStore {
    package func createList(_ draft: TodoListDraft) -> TodoWriteResult {
        guard access == .allowed,
              let source = store.sources.first(where: { $0.sourceIdentifier == draft.accountID }) else { return .missing }
        let list = EKCalendar(for: .reminder, eventStore: store)
        list.title = draft.name
        list.source = source
        if let c = TodoMapping.rgb(fromHex: draft.colorHex) {
            list.cgColor = NSColor(srgbRed: c.red, green: c.green, blue: c.blue, alpha: 1).cgColor
        }
        return saveList(list)
    }

    package func renameList(_ id: String, to name: String) -> TodoWriteResult {
        guard let list = writableList(id) else { return .missing }
        list.title = name
        return saveList(list)
    }

    private func saveList(_ list: EKCalendar) -> TodoWriteResult {
        do {
            try store.saveCalendar(list, commit: true)
        } catch {
            return .failed
        }
        return didWrite(.done(id: list.calendarIdentifier))
    }
}
