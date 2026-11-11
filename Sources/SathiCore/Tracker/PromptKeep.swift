import Foundation

package enum PromptKeep: Equatable, Sendable {
    case continueLast(String)
    case keep(String)
    case keepGoing(Int)
    case stillOnLate
    case backTo(String)

    package var label: String { Copywriter.activityPromptKeep(self) }
}
