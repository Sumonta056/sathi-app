import Foundation

package struct ActivityEdit: Equatable, Sendable {
    package var text: String
    package var category: String?
    package var start: Date
    package var end: Date

    package init(text: String, category: String?, start: Date, end: Date) {
        self.text = text
        self.category = category
        self.start = start
        self.end = end
    }
}

package enum ActivityEditResult: Equatable, Sendable {
    case saved(ActivityID)
    case emptyText
    case tooShort
    case overlap
    case notFound
}
