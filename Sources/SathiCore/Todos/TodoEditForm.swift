import Foundation

package struct TodoEditForm: Equatable {
    package var title: String
    package var notes: String
    package var listID: String
    package var hasDate: Bool
    package var date: Date
    package var minutes: Int?

    package init(todo: Todo, calendar: Calendar) {
        title = todo.title
        notes = todo.notes
        listID = todo.listID
        hasDate = todo.due != nil
        date = todo.due?.date ?? calendar.startOfDay(for: todo.createdAt)
        if let due = todo.due, due.hasTime {
            let c = calendar.dateComponents([.hour, .minute], from: due.date)
            minutes = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        } else {
            minutes = nil
        }
    }

    package var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    package var isValid: Bool { !trimmedTitle.isEmpty }

    package func edit(calendar: Calendar) -> TodoEdit {
        TodoEdit(title: trimmedTitle, notes: notes, due: due(calendar: calendar))
    }

    private func due(calendar: Calendar) -> TodoDue? {
        guard hasDate else { return nil }
        let start = calendar.startOfDay(for: date)
        guard let minutes else { return TodoDue(date: start, hasTime: false) }
        let at = calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: start) ?? start
        return TodoDue(date: at, hasTime: true)
    }
}
