import SathiCore

enum BuddyKind {
    case drop, book
}

extension HabitID {
    var kind: BuddyKind { self == .water ? .drop : .book }
}
