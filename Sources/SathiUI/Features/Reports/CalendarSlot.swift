import SathiCore

enum CalendarSlot: Identifiable {
    case weekday(Int)
    case blank(Int)
    case day(StreakCell)

    var id: String {
        switch self {
        case let .weekday(i): "weekday-\(i)"
        case let .blank(i): "blank-\(i)"
        case let .day(cell): "day-\(cell.day)"
        }
    }
}
