import Foundation

package struct AwayPlan: Codable, Equatable, Sendable {
    package var place: AwayPlace
    package var name: String?

    package init(place: AwayPlace, name: String? = nil) {
        self.place = place
        self.name = name
    }
}
