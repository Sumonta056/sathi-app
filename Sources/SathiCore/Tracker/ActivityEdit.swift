import Foundation

package struct ActivityEdit: Equatable, Sendable {
    package var text: String
    package var category: String?
    package var start: Date
    package var end: Date
    package var awayPlace: AwayPlace?
    package var awayPlaceName: String?
    package var calendar: ActivityCalendarChoice
    package var kind: ActivityKind?

    package init(
        text: String, category: String?, start: Date, end: Date,
        awayPlace: AwayPlace? = nil, awayPlaceName: String? = nil, calendar: ActivityCalendarChoice = .keep,
        kind: ActivityKind? = nil
    ) {
        self.text = text
        self.kind = kind
        self.calendar = calendar
        self.category = category
        self.start = start
        self.end = end
        self.awayPlace = awayPlace
        self.awayPlaceName = awayPlace == .other ? awayPlaceName : nil
    }

    var wholeSeconds: ActivityEdit {
        var e = self
        e.start = start.wholeSecond
        e.end = end.wholeSecond
        return e
    }
}

package enum ActivityCalendarChoice: Equatable, Sendable {
    case keep
    case none
    case calendar(String)
}

package enum ActivityEditResult: Equatable, Sendable {
    case saved(ActivityID)
    case calendarFailed(ActivityID)
    case calendarUnchanged(ActivityID)
    case emptyText
    case tooShort
    case overlap
    case crossesMidnight
    case inFuture
    case awayUndo
    case notFound
}

package enum CalendarEditOutcome: Equatable, Sendable {
    case ok
    case unchanged
    case oldEventKept
}
