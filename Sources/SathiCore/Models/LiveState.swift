import Foundation

package struct LiveState: Codable, Equatable, Sendable {
    package var bottleLevel: Double = 1
    package var lastWaterDone: Date?
    package var streakReset: [String: Date] = [:]

    package init() {}
}

extension LiveState {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = LiveState()
        bottleLevel = try c.value(.bottleLevel, or: d.bottleLevel)
        lastWaterDone = try c.decodeIfPresent(Date.self, forKey: .lastWaterDone)?.wholeSecond
        streakReset = try c.value(.streakReset, or: d.streakReset).mapValues(\.wholeSecond)
    }
}
