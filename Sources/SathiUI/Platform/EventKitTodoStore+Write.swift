import EventKit
import SathiCore

extension EventKitTodoStore {
    package func add(_ draft: TodoDraft) -> TodoWriteResult {
        guard let list = writableList(draft.listID) else { return .missing }
        let r = EKReminder(eventStore: store)
        r.calendar = list
        r.title = draft.title
        r.notes = draft.notes.isEmpty ? nil : draft.notes
        r.dueDateComponents = draft.due.map { TodoMapping.components(for: $0, calendar: .current) }
        return commit(r)
    }

    package func update(_ id: String, _ edit: TodoEdit) -> TodoWriteResult {
        guard let r = reminder(id) else { return .missing }
        r.title = edit.title
        r.notes = edit.notes.isEmpty ? nil : edit.notes
        r.dueDateComponents = edit.due.map { TodoMapping.components(for: $0, calendar: .current) }
        return commit(r)
    }

    package func setDone(_ id: String, _ done: Bool) -> TodoWriteResult {
        guard let r = reminder(id) else { return .missing }
        r.isCompleted = done
        return commit(r)
    }

    package func move(_ id: String, to listID: String) -> TodoWriteResult {
        guard let r = reminder(id), let list = writableList(listID) else { return .missing }
        r.calendar = list
        return commit(r)
    }

    package func delete(_ id: String) -> TodoWriteResult {
        guard let r = reminder(id) else { return .missing }
        do {
            try store.remove(r, commit: true)
        } catch {
            return .failed
        }
        return didWrite(.done(id: id))
    }

    private func commit(_ r: EKReminder) -> TodoWriteResult {
        do {
            try store.save(r, commit: true)
        } catch {
            return .failed
        }
        return didWrite(.done(id: r.calendarItemIdentifier))
    }
}
