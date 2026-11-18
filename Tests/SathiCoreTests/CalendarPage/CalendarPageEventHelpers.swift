import Foundation
import SathiCore
import SathiTestSupport

func pageEvent(
    _ id: String = "e1",
    calendar: String = "work",
    repeating: Bool = false,
    guests: Bool = false,
    allDay: Bool = false
) -> CalendarEventInfo {
    CalendarEventInfo(
        id: id, title: "Plan", start: day(2026, 3, 4, 15), end: day(2026, 3, 4, 16), calendarID: calendar,
        isAllDay: allDay, isRepeating: repeating, hasGuests: guests
    )
}

extension EngineHarness {
    func showPage(_ events: [CalendarEventInfo]) {
        calendarWriter.eventsValue = events
        _ = engine.calendarPageBase(.containing(day(2026, 3, 4, 12), kind: .day, calendar: engine.calendar))
    }

    var writerCalls: Int {
        calendarWriter.saved.count + calendarWriter.updated.count + calendarWriter.timesUpdated.count
            + calendarWriter.deleted.count
    }
}
