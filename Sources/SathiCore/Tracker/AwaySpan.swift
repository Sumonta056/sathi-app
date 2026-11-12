import Foundation

package struct AwaySpan: Codable, Equatable, Sendable {
    package var start: Date
    package var end: Date
    package var cause: AwayCause
    package var place: AwayPlace?
    package var placeName: String?

    package init(start: Date, end: Date, cause: AwayCause, place: AwayPlace? = nil, placeName: String? = nil) {
        self.start = start
        self.end = end
        self.cause = cause
        self.place = place
        self.placeName = placeName
    }

    package var fromIdle: Bool { cause == .idle }
}
