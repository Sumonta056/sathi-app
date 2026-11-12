import Foundation

package struct TrackerAwayDetails: Codable, Equatable, Sendable {
    package var lastAway: AwaySpan?
    package var awayItems: [ActivityID] = []
    package var endedByAway: RunningActivity?
    package var endedMergedInto: Activity?
    package var loggedWhileAway: [Activity] = []

    package init() {}
}

extension TrackerAwayDetails {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        lastAway = c.lenient(.lastAway, or: AwaySpan?.none)
        awayItems = c.lenientArray(.awayItems)
        endedByAway = c.lenient(.endedByAway, or: RunningActivity?.none)
        endedMergedInto = c.lenient(.endedMergedInto, or: Activity?.none)
        loggedWhileAway = c.lenientArray(.loggedWhileAway)
    }
}
