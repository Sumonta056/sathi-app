import SathiCore

enum BuddyKind {
    case drop, book, pebble, kettlebell
}

extension HabitID {
    var kind: BuddyKind {
        switch self {
        case .water: return .drop
        case .reading: return .book
        case .meditation: return .pebble
        case .gym: return .kettlebell
        }
    }
}
