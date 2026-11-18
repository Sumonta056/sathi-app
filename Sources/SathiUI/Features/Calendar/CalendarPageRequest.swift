import SathiCore

struct CalendarPageRequest: Equatable {
    let range: CalendarPageRange
    let narrow: Set<CalendarLaneShape>
}
