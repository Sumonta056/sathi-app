import SathiCore

enum BuddyKind {
    case drop, book
}

extension HabitID {
    var kind: BuddyKind {
        switch self {
        case .water: return .drop
        case .reading: return .book
        }
    }
}
