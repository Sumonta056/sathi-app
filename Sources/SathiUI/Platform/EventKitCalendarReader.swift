import EventKit
import SathiCore

extension EventKitCalendarWriter {
    @discardableResult
    package func delete(eventID: String) -> Bool {
        guard !eventID.isEmpty, access == .allowed else { return false }
        guard let event = store.event(withIdentifier: eventID) else { return true }
        guard !EventKitCalendarReaderMapping.isLocked(event) else { return false }
        do {
            try store.remove(event, span: .thisEvent, commit: true)
        } catch {
            return false
        }
        return true
    }

    package func readableCalendars() -> [CalendarChoice] {
        guard access == .allowed else { return [] }
        let choices = store.calendars(for: .event).map { calendar in
            CalendarChoice(
                id: calendar.calendarIdentifier,
                title: calendar.title,
                account: calendar.source?.title ?? "",
                colorHex: Self.hex(of: calendar.cgColor)
            )
        }
        return CalendarMapping.sorted(choices)
    }

    package func events(from start: Date, to end: Date, calendarIDs: [String]) -> [CalendarEventInfo] {
        guard EventKitCalendarReaderMapping.isReadable(from: start, to: end, calendarIDs: calendarIDs),
              access == .allowed else { return [] }
        let calendars = calendarIDs.compactMap { store.calendar(withIdentifier: $0) }
        guard !calendars.isEmpty else { return [] }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
        return store.events(matching: predicate)
            .compactMap(EventKitCalendarReaderMapping.info)
            .sorted { $0.start < $1.start }
    }
}
