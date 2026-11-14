import EventKit
import SathiCore

enum EventKitEventEdit {
    static func applyNew(_ draft: CalendarEventDraft, calendar: EKCalendar, to event: EKEvent) {
        applyTimes(draft, calendar: calendar, to: event)
        event.alarms = nil
    }

    static func applyTimes(_ draft: CalendarEventDraft, calendar: EKCalendar, to event: EKEvent) {
        event.title = draft.title
        event.calendar = calendar
        event.startDate = draft.start
        event.endDate = draft.end
    }
}
