import Foundation

package enum CalendarPageWriteResult: Equatable, Sendable {
    case saved(String)
    case failed
    case invalid
}

extension Engine {
    static let calendarEventURLPrefix = "ical://ekevent/"

    package var calendarPageWritableCalendars: [CalendarChoice] { calendarChoices() }

    package var calendarPageDefaultCalendarID: String? {
        let ids = calendarPageWritableCalendars.map(\.id)
        let candidates = [data.prefs.calendarPage.lastCalendarID, calendarWriter.defaultCalendarID()]
        return candidates.compactMap { $0 }.first(where: ids.contains) ?? ids.first
    }

    package func calendarPageNewEvent(at slot: Date) -> CalendarEventForm {
        CalendarEventForm.newEvent(at: slot, calendarID: calendarPageDefaultCalendarID, calendar: calendar)
    }

    package func calendarPageForm(for e: CalendarEventInfo) -> CalendarEventForm {
        let writable = calendarPageWritableCalendars.contains { $0.id == e.calendarID }
        return CalendarEventForm(
            eventID: e.id,
            title: e.title,
            start: e.start,
            end: e.end,
            calendarID: e.calendarID,
            readOnly: e.isReadOnlyInSathi || e.isAllDay || !writable
        )
    }

    package func saveCalendarPageEvent(_ f: CalendarEventForm) -> CalendarPageWriteResult {
        guard f.canSave, let calendarID = f.calendarID, let title = CalendarEventText.clean(f.title) else { return .invalid }
        if let id = f.eventID, calendarPageEditableEvent(id, around: DateInterval(start: f.start, end: f.end)) == nil {
            return .invalid
        }
        let draft = CalendarEventDraft(calendarID: calendarID, title: title, start: f.start.wholeSecond, end: f.end.wholeSecond)
        let result = f.eventID.map { calendarWriter.update(eventID: $0, draft: draft) } ?? calendarWriter.save(draft)
        guard case let .saved(id) = result, !id.isEmpty else { return .failed }
        data.prefs.calendarPage.lastCalendarID = calendarID
        calendarPageWritten()
        return .saved(id)
    }

    @discardableResult
    package func deleteCalendarPageEvent(_ id: String) -> Bool {
        guard calendarPageEditableEvent(id, around: nil) != nil, calendarWriter.delete(eventID: id) else { return false }
        calendarPageEventsByID[id] = nil
        calendarPageWritten()
        return true
    }

    package func openEventInCalendar(_ id: String) {
        let path = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
        guard let url = URL(string: Self.calendarEventURLPrefix + path) else { return }
        links.open(url)
    }

    private func calendarPageWritten() {
        markTrackerEventsStale()
        storesChanged()
        requestTick()
    }
}
