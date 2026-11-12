import Foundation

package struct ActivityDraft: Codable, Equatable, Sendable {
    package var text: String
    package var category: String?
    package var length: ActivityLength
    package var askOffsetMinutes: Int
    package var calendarID: String?
    package var quiet: Bool
    package var sourceEventID: String?

    package init(
        text: String,
        category: String? = nil,
        length: ActivityLength = .minutes(Limits.trackerUsualLengthDefault),
        askOffsetMinutes: Int = 0,
        calendarID: String? = nil,
        quiet: Bool = false,
        sourceEventID: String? = nil
    ) {
        self.text = text
        self.category = category
        self.length = length
        self.askOffsetMinutes = askOffsetMinutes
        self.calendarID = calendarID
        self.quiet = quiet
        self.sourceEventID = sourceEventID
    }
}

extension ActivityDraft {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = ActivityDraft(text: "")
        text = try c.decode(String.self, forKey: .text)
        category = c.lenient(.category, or: d.category)
        length = c.lenient(.length, or: d.length)
        askOffsetMinutes = c.lenient(.askOffsetMinutes, or: d.askOffsetMinutes)
        calendarID = c.lenient(.calendarID, or: d.calendarID)
        quiet = c.lenient(.quiet, or: d.quiet)
        sourceEventID = c.lenient(.sourceEventID, or: d.sourceEventID)
    }
}
