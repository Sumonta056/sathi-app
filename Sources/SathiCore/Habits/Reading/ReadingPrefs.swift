import Foundation

package struct ReadingPrefs: Codable, Equatable, Sendable {
    package var enabled = true
    package var timeMinutes = 22 * 60
    package var sessionMinutes = 15
    package var strictness: Strictness = .persistent

    package init() {}
}

extension ReadingPrefs {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = ReadingPrefs()
        enabled = try c.value(.enabled, or: d.enabled)
        timeMinutes = try c.value(.timeMinutes, or: d.timeMinutes)
        sessionMinutes = try c.value(.sessionMinutes, or: d.sessionMinutes)
        strictness = try c.value(.strictness, or: d.strictness)
    }
}
