import SathiCore
import SwiftUI

enum ActivityColors {
    static let fallbackHex: UInt32 = 0xFF8A80
    static let eventHex: UInt32 = 0x7FB8FF
    static let awayHex: UInt32 = 0x3A4458

    static func color(_ category: String?, in categories: [ActivityCategory]) -> Color {
        guard let category, let found = categories.first(where: { $0.name == category }) else { return Night.tracker }
        return Night.category(found.colorHex)
    }

    static func hex(_ category: String?, in categories: [ActivityCategory]) -> UInt32 {
        guard let category, let found = categories.first(where: { $0.name == category }) else { return fallbackHex }
        return found.colorHex
    }

    static func color(_ segment: ActivitySegment, in categories: [ActivityCategory]) -> Color {
        switch segment.kind {
        case .work: return color(segment.activity?.category, in: categories)
        case .away: return Night.trackerAway
        case .notLogged: return Night.trackerNotLogged
        }
    }
}
