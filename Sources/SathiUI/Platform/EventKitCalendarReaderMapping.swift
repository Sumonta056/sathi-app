import EventKit
import SathiCore

enum EventKitCalendarReaderMapping {
    static func isReadable(from start: Date, to end: Date, calendarIDs: [String]) -> Bool {
        !calendarIDs.isEmpty && end > start
    }

    static func info(_ event: EKEvent) -> CalendarEventInfo? {
        guard let id = event.eventIdentifier,
              let calendarID = event.calendar?.calendarIdentifier else { return nil }
        let declined = event.attendees?.contains { $0.isCurrentUser && $0.participantStatus == .declined } ?? false
        return CalendarEventInfo(
            id: id,
            title: event.title ?? "",
            start: event.startDate,
            end: event.endDate,
            calendarID: calendarID,
            isAllDay: event.isAllDay,
            declined: declined,
            isRepeating: event.hasRecurrenceRules,
            hasGuests: event.hasAttendees
        )
    }
}
