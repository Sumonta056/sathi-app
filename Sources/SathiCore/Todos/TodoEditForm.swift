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
        minutes = todo.due?.minutes(calendar: calendar)
    }

    package var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    package var isValid: Bool { !trimmedTitle.isEmpty }

    package func edit(calendar: Calendar) -> TodoEdit {
        TodoEdit(
            title: trimmedTitle,
            notes: notes,
            due: TodoDue.make(hasDate: hasDate, date: date, minutes: minutes, calendar: calendar)
        )
    }
}
