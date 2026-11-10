import Foundation

package struct AwaySpan: Codable, Equatable, Sendable {
    package var start: Date
    package var end: Date
    package var cause: AwayCause
    package var place: AwayPlace?

    package init(start: Date, end: Date, cause: AwayCause, place: AwayPlace? = nil) {
        self.start = start
        self.end = end
        self.cause = cause
        self.place = place
    }

    package var fromIdle: Bool { cause == .idle }
}
