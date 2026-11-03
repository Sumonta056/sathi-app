import Foundation

package struct QuickPrefs: Codable, Equatable, Sendable {
    package var strictness: Strictness = .persistent
    package var showsCloseButton = true

    package init() {}
}

extension QuickPrefs {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = QuickPrefs()
        strictness = try c.known(.strictness, or: d.strictness)
        showsCloseButton = try c.value(.showsCloseButton, or: d.showsCloseButton)
    }
}
