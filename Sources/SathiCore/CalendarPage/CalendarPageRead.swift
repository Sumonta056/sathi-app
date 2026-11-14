import Foundation

struct CalendarPageReadKey: Equatable {
    let interval: DateInterval
    let stores: Int
    let hidden: Set<String>
    let access: CalendarAccess
}

struct CalendarPageRead {
    let key: CalendarPageReadKey
    let readable: [CalendarChoice]
    let events: [CalendarEventInfo]
}
