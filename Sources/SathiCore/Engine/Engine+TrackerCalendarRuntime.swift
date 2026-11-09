import Foundation

struct TrackerCalendarRuntime: Equatable {
    var events: [CalendarEventInfo] = []
    var readAt: Date?
    var note: TrackerNote?
    var noteUntil: Date?
}
