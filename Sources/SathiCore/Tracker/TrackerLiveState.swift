import Foundation

package struct TrackerLiveState: Codable, Equatable, Sendable {
    package var running: RunningActivity?
    package var prompt: PromptState?
    package var awaySince: Date?
    package var awayCause: AwayCause?
    package var lastInput: Date?
    package var lastEndOfDay: DayKey?
    package var lastActivity: ActivityDraft?
    package var beforeSession: ActivityDraft?
    package var away = TrackerAwayDetails()

    package init() {}
}

extension TrackerLiveState {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        running = c.lenient(.running, or: RunningActivity?.none)
        prompt = c.lenient(.prompt, or: PromptState?.none)
        awaySince = c.lenient(.awaySince, or: Date?.none)?.wholeSecond
        awayCause = c.lenient(.awayCause, or: String?.none).flatMap(AwayCause.init(rawValue:))
        lastInput = c.lenient(.lastInput, or: Date?.none)?.wholeSecond
        lastEndOfDay = c.lenient(.lastEndOfDay, or: DayKey?.none)
        lastActivity = c.lenient(.lastActivity, or: ActivityDraft?.none)
        beforeSession = c.lenient(.beforeSession, or: ActivityDraft?.none)
        away = c.lenient(.away, or: TrackerAwayDetails())
    }
}
