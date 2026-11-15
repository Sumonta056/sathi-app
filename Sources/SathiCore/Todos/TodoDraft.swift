import Foundation

package struct TodoDraft: Equatable, Sendable {
    package var listID: String
    package var title: String
    package var notes: String
    package var due: TodoDue?

    package init(listID: String, title: String, notes: String, due: TodoDue?) {
        self.listID = listID
        self.title = title
        self.notes = notes
        self.due = due
    }

    package var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    package var isValid: Bool { !trimmedTitle.isEmpty }
}

package struct TodoEdit: Equatable, Sendable {
    package var title: String
    package var notes: String
    package var due: TodoDue?

    package init(title: String, notes: String, due: TodoDue?) {
        self.title = title
        self.notes = notes
        self.due = due
    }
}
