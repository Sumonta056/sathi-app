import SathiCore

struct CalendarPageRequest: Equatable {
    let range: CalendarPageRange
    let narrow: Bool
}

@MainActor
enum CalendarNarrowMemory {
    static var week = false
}
