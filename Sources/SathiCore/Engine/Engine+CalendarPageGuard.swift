import Foundation

extension Engine {
    func calendarPageEditableEvent(_ id: String, around fallback: DateInterval?) -> CalendarEventInfo? {
        guard !id.isEmpty else { return nil }
        let shown = calendarPageEventsByID[id].map { DateInterval(start: $0.start, end: max($0.start, $0.end)) }
        guard let span = shown ?? fallback else { return nil }
        let ids = calendarWriter.readableCalendars().map(\.id)
        guard !ids.isEmpty else { return nil }
        let found = calendarWriter.events(
            from: span.start.addingTimeInterval(-Timing.minute),
            to: span.end.addingTimeInterval(Timing.minute),
            calendarIDs: ids
        ).first { $0.id == id }
        guard let e = found, !calendarPageForm(for: e).readOnly else { return nil }
        return e
    }
}
