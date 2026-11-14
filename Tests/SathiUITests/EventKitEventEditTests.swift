import EventKit
import Foundation
import SathiCore
@testable import SathiUI
import Testing

@MainActor
@Suite("EventKit event edit")
struct EventKitEventEditTests {
    private let store = EKEventStore()

    private func userEvent() -> EKEvent {
        let event = EKEvent(eventStore: store)
        event.title = "Dentist"
        event.startDate = Date(timeIntervalSinceReferenceDate: 800_000_000)
        event.endDate = event.startDate.addingTimeInterval(3600)
        event.addAlarm(EKAlarm(relativeOffset: -86400))
        event.addAlarm(EKAlarm(relativeOffset: -3600))
        event.notes = "Bring the card"
        event.location = "Main street 4"
        event.url = URL(string: "https://example.com/visit")
        event.availability = .free
        return event
    }

    private func draft(_ event: EKEvent) -> CalendarEventDraft {
        CalendarEventDraft(
            calendarID: "c", title: "Dentist v2",
            start: event.startDate.addingTimeInterval(1800), end: event.endDate.addingTimeInterval(1800)
        )
    }

    @Test func pageEditKeepsAlarmsAndEveryOtherField() {
        let event = userEvent()
        let d = draft(event)
        let alarms = event.alarms?.count ?? 0
        let availability = event.availability
        #expect(alarms > 0)
        EventKitEventEdit.applyTimes(d, calendar: EKCalendar(for: .event, eventStore: store), to: event)
        #expect(event.alarms?.count == alarms)
        #expect(event.notes == "Bring the card")
        #expect(event.location == "Main street 4")
        #expect(event.url == URL(string: "https://example.com/visit"))
        #expect(event.availability == availability)
        #expect(event.title == "Dentist v2")
        #expect(event.startDate == d.start)
        #expect(event.endDate == d.end)
    }

    @Test func sathiEventWriteClearsAlarms() {
        let event = userEvent()
        EventKitEventEdit.applyNew(draft(event), calendar: EKCalendar(for: .event, eventStore: store), to: event)
        #expect(event.alarms?.isEmpty ?? true)
    }
}
