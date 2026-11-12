import Foundation

package struct RunningActivity: Codable, Equatable, Sendable {
    package var id: ActivityID
    package var kind: ActivityKind
    package var text: String
    package var category: String?
    package var start: Date
    package var expectedLength: ActivityLength
    package var askAt: Date
    package var lastAnswer: Date
    package var confirmedUntil: Date
    package var calendarID: String?
    package var quietUntil: Date?
    package var sourceEventID: String?

    package init(
        id: ActivityID = ActivityID(),
        kind: ActivityKind = .work,
        text: String,
        category: String? = nil,
        start: Date,
        expectedLength: ActivityLength,
        askAt: Date
    ) {
        self.id = id
        self.kind = kind
        self.text = text
        self.category = category
        self.start = start.wholeSecond
        self.expectedLength = expectedLength
        self.askAt = askAt.wholeSecond
        lastAnswer = start.wholeSecond
        confirmedUntil = askAt.wholeSecond
    }

    package func activity(until end: Date) -> Activity {
        Activity(
            id: id, kind: kind, text: text, category: category, start: start, end: end,
            calendarID: calendarID, sourceEventID: sourceEventID
        )
    }
}

extension RunningActivity {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(ActivityID.self, forKey: .id)
        kind = (try? c.known(.kind, or: ActivityKind.work)) ?? .work
        text = try c.decode(String.self, forKey: .text)
        category = c.lenient(.category, or: String?.none)
        start = try c.decode(Date.self, forKey: .start).wholeSecond
        expectedLength = c.lenient(.expectedLength, or: ActivityLength.open)
        askAt = try c.decode(Date.self, forKey: .askAt).wholeSecond
        lastAnswer = (c.lenient(.lastAnswer, or: Date?.none) ?? start).wholeSecond
        confirmedUntil = (c.lenient(.confirmedUntil, or: Date?.none) ?? askAt).wholeSecond
        calendarID = c.lenient(.calendarID, or: String?.none)
        quietUntil = c.lenient(.quietUntil, or: Date?.none)?.wholeSecond
        sourceEventID = c.lenient(.sourceEventID, or: String?.none)
    }
}
