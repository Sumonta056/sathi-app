import Foundation
import SathiCore

extension EventKitCalendarWriter {
    @discardableResult
    package func delete(eventID: String) -> Bool { false }

    package func readableCalendars() -> [CalendarChoice] { [] }

    package func events(from start: Date, to end: Date, calendarIDs: [String]) -> [CalendarEventInfo] { [] }
}
