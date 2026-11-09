import Foundation

package enum AwayPlace: String, Codable, CaseIterable, Sendable {
    case lunch
    case meeting
    case walk
    case commute
    case other
    case breakTime = "break"

    package static let choices: [AwayPlace] = [.lunch, .meeting, .walk, .commute, .other]
}

package enum AwayCause: String, Codable, CaseIterable, Sendable {
    case locked
    case asleep
    case idle
    case onBreak
}
