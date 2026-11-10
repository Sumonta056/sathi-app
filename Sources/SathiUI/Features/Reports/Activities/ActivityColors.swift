import SathiCore
import SwiftUI

enum ActivityColors {
    static func color(_ category: String?, in categories: [ActivityCategory]) -> Color {
        guard let category, let found = categories.first(where: { $0.name == category }) else { return Night.tracker }
        return Night.category(found.colorHex)
    }

    static func color(_ segment: ActivitySegment, in categories: [ActivityCategory]) -> Color {
        switch segment.kind {
        case .work: return color(segment.activity?.category, in: categories)
        case .away: return Night.trackerAway
        case .notLogged: return Night.trackerNotLogged
        }
    }
}
