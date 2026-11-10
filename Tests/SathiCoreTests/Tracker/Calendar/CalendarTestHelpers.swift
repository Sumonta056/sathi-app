import Foundation
import SathiCore
import SathiTestSupport

func meeting(
    _ id: String = "m1",
    _ title: String = "Standup",
    from start: Date,
    to end: Date,
    calendar: String = "work",
    allDay: Bool = false,
    declined: Bool = false
) -> CalendarEventInfo {
    CalendarEventInfo(id: id, title: title, start: start, end: end, calendarID: calendar, isAllDay: allDay, declined: declined)
}

extension EngineHarness {
    func useEvents(_ events: [CalendarEventInfo], read: [String] = ["work"], mode: EventMode = .logAndTell) {
        calendarWriter.eventsValue = events
        engine.data.prefs.tracker.readCalendarIDs = read
        engine.data.prefs.tracker.eventMode = mode
        engine.data.prefs.tracker.readsEvents = true
        engine.tick()
    }

    var notes: [TrackerNote] {
        presenter.trackerCalls.compactMap { if case let .showNote(n) = $0 { n } else { nil } }
    }

    var noteCloses: Int { presenter.trackerCalls.count { $0 == .closeNote } }

    var eventItems: [Activity] { saved.filter { $0.sourceEventID != nil } }
}
