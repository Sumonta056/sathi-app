import Foundation

package struct ActivityEdit: Equatable, Sendable {
    package var text: String
    package var category: String?
    package var start: Date
    package var end: Date
    package var awayPlace: AwayPlace?

    package init(text: String, category: String?, start: Date, end: Date, awayPlace: AwayPlace? = nil) {
        self.text = text
        self.category = category
        self.start = start
        self.end = end
        self.awayPlace = awayPlace
    }

    var wholeSeconds: ActivityEdit {
        var e = self
        e.start = start.wholeSecond
        e.end = end.wholeSecond
        return e
    }
}

package enum ActivityEditResult: Equatable, Sendable {
    case saved(ActivityID)
    case emptyText
    case tooShort
    case overlap
    case crossesMidnight
    case inFuture
    case notFound
}
