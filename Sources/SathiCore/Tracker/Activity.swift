import Foundation

package struct Activity: Codable, Equatable, Identifiable, Sendable {
    package var id: ActivityID
    package var kind: ActivityKind
    package var text: String
    package var category: String?
    package var start: Date
    package var end: Date
    package var awayPlace: AwayPlace?
    package var calendarID: String?
    package var eventID: String?
    package var sourceEventID: String?
    package var awayPlaceName: String?

    package init(
        id: ActivityID = ActivityID(),
        kind: ActivityKind = .work,
        text: String,
        category: String? = nil,
        start: Date,
        end: Date,
        awayPlace: AwayPlace? = nil,
        calendarID: String? = nil,
        eventID: String? = nil,
        sourceEventID: String? = nil,
        awayPlaceName: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.text = text
        self.category = category
        self.start = start.wholeSecond
        self.end = end.wholeSecond
        self.awayPlace = awayPlace
        self.calendarID = calendarID
        self.eventID = eventID
        self.sourceEventID = sourceEventID
        self.awayPlaceName = awayPlaceName
    }

    package var length: TimeInterval { end.timeIntervalSince(start) }
    package var interval: DateInterval { DateInterval(start: start, end: max(start, end)) }
    package var awayText: String { Copywriter.trackerAwayText(awayPlace, name: awayPlaceName) }
}

extension Activity {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(ActivityID.self, forKey: .id)
        kind = try c.decode(ActivityKind.self, forKey: .kind)
        start = try c.decode(Date.self, forKey: .start).wholeSecond
        end = try c.decode(Date.self, forKey: .end).wholeSecond
        text = c.lenient(.text, or: "")
        category = c.lenient(.category, or: String?.none)
        awayPlace = c.lenient(.awayPlace, or: String?.none).flatMap(AwayPlace.init(rawValue:))
        calendarID = c.lenient(.calendarID, or: String?.none)
        eventID = c.lenient(.eventID, or: String?.none)
        sourceEventID = c.lenient(.sourceEventID, or: String?.none)
        awayPlaceName = c.lenient(.awayPlaceName, or: String?.none)
    }
}
