import Foundation

extension Copywriter {
    package static let calendarNewEvent = "New event"
    package static let calendarEditEvent = "Edit event"
    package static let calendarEventHeading = "Event"
    package static let calendarEventTitle = "Title"
    package static let calendarEventTime = "Time"
    package static let calendarEventCalendar = "Calendar"
    package static let calendarEventTo = "to"
    package static let calendarEventHint = "Sathi saves this event to your macOS calendar."
    package static let calendarEventReadOnly = "Sathi cannot change this event. Change it in Calendar."
    package static let calendarEventSave = "Save"
    package static let calendarEventCancel = "Cancel"
    package static let calendarEventDelete = "Delete"
    package static let calendarOpenInCalendar = "Open in Calendar"
    package static let calendarEventSaveFailed = "Sathi could not save this event. Try again."
    package static let calendarEventChanged = "This event changed in Calendar and Sathi can't edit it now. Open it in Calendar."
    package static let calendarEventDeleteFailed = "Sathi could not delete this event. Try again."
    package static let calendarShownTitle = "Shown calendars"
    package static let calendarByCategory = "By category"
    package static let calendarTracked = "Tracked"
    package static let calendarPlannedEvents = "Planned events"
    package static let calendarAway = "Away"
    package static let calendarNothingTracked = "Nothing tracked yet."

    package static func calendarHours(_ seconds: TimeInterval) -> String {
        let minutes = Int(max(0, seconds) / Timing.minute)
        let h = minutes / Limits.minutesPerHour
        let m = minutes % Limits.minutesPerHour
        return h == 0 ? "\(m) m" : "\(h) h " + String(format: "%02d", m) + " m"
    }

    package static func calendarStatsTitle(_ kind: ReportRange) -> String {
        "This " + kind.rawValue
    }

    package static func calendarStatsLine(_ stats: CalendarPageStats, kind: ReportRange) -> String {
        "Tracked this \(kind.rawValue): \(calendarHours(stats.tracked)) · Planned: \(calendarHours(stats.planned))"
    }

    package static func calendarEventDate(_ day: DayKey, calendar: Calendar) -> String {
        let g = Calendar.gregorian(in: calendar.timeZone)
        return rangeDate(day.start(in: g), "EEE d MMM", calendar.timeZone)
    }
}
