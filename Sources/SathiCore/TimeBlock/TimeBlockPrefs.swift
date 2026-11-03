import Foundation

package struct TimeBlockPrefs: Codable, Equatable, Sendable {
    package var defaultCalendarID: String?
    package var lastLength: TimeBlockLength = .minutes(30)
    package var display: TimeBlockDisplay = .menuBar
    package var playsSound = true

    package init() {}
}

extension TimeBlockPrefs {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = TimeBlockPrefs()
        defaultCalendarID = c.lenient(.defaultCalendarID, or: d.defaultCalendarID)
        lastLength = c.lenient(.lastLength, or: d.lastLength)
        display = (try? c.known(.display, or: d.display)) ?? d.display
        playsSound = c.lenient(.playsSound, or: d.playsSound)
    }
}
