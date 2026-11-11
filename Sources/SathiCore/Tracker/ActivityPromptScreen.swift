import Foundation

package struct ActivityPromptScreen: Equatable, Sendable {
    package var reason: PromptReason
    package var tag: String
    package var timeText: String
    package var title: String
    package var message: String
    package var showsWhere = false
    package var keep: PromptKeep?
    package var startLabel: String
    package var skip: PromptSkip
    package var startedChoices: [Date] = []
    package var fixedStart: Date?
    package var calendarNote: String?
    package var showsIWasHere = false

    package init(reason: PromptReason, tag: String, timeText: String, title: String, message: String, startLabel: String, skip: PromptSkip) {
        self.reason = reason
        self.tag = tag
        self.timeText = timeText
        self.title = title
        self.message = message
        self.startLabel = startLabel
        self.skip = skip
    }

    package var keepLabel: String? { keep?.label }
}
