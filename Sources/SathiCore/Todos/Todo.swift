import Foundation

package struct Todo: Equatable, Sendable {
    package var id: String
    package var listID: String
    package var title: String
    package var notes: String
    package var due: TodoDue?
    package var priority: Int
    package var isDone: Bool
    package var doneAt: Date?
    package var createdAt: Date
    package var repeats: Bool
    package var url: URL?

    package init(
        id: String,
        listID: String,
        title: String,
        notes: String,
        due: TodoDue?,
        priority: Int,
        isDone: Bool,
        doneAt: Date?,
        createdAt: Date,
        repeats: Bool,
        url: URL?
    ) {
        self.id = id
        self.listID = listID
        self.title = title
        self.notes = notes
        self.due = due
        self.priority = priority
        self.isDone = isDone
        self.doneAt = doneAt
        self.createdAt = createdAt
        self.repeats = repeats
        self.url = url
    }
}
