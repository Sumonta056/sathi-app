import Foundation

package struct PromptState: Codable, Equatable, Sendable {
    package var kind: PromptKind
    package var shownAt: Date
    package var askTime: Date
    package var switchFrom: Date?
    package var resume: ActivityDraft?
    package var eventID: String?

    package init(
        kind: PromptKind,
        shownAt: Date,
        askTime: Date,
        switchFrom: Date? = nil,
        resume: ActivityDraft? = nil,
        eventID: String? = nil
    ) {
        self.kind = kind
        self.shownAt = shownAt.wholeSecond
        self.askTime = askTime.wholeSecond
        self.switchFrom = switchFrom?.wholeSecond
        self.resume = resume
        self.eventID = eventID
    }
}

extension PromptState {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decode(PromptKind.self, forKey: .kind)
        shownAt = try c.decode(Date.self, forKey: .shownAt).wholeSecond
        askTime = try c.decode(Date.self, forKey: .askTime).wholeSecond
        switchFrom = c.lenient(.switchFrom, or: Date?.none)?.wholeSecond
        resume = c.lenient(.resume, or: ActivityDraft?.none)
        eventID = c.lenient(.eventID, or: String?.none)
    }
}
