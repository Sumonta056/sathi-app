import Foundation

package struct CalendarEventForm: Equatable, Sendable {
    package var eventID: String?
    package var title: String
    package var start: Date
    package var end: Date
    package var calendarID: String?
    package var readOnly: Bool

    package init(eventID: String?, title: String, start: Date, end: Date, calendarID: String?, readOnly: Bool) {
        self.eventID = eventID
        self.title = title
        self.start = start
        self.end = end
        self.calendarID = calendarID
        self.readOnly = readOnly
    }

    package static func newEvent(at slot: Date, calendarID: String?, calendar: Calendar) -> CalendarEventForm {
        var parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: slot)
        let minute = parts.minute ?? 0
        parts.minute = minute - minute % Limits.calendarSlotMinutes
        let start = calendar.date(from: parts) ?? slot
        let end = start.addingTimeInterval(TimeInterval(Limits.calendarNewEventMinutes) * Timing.minute)
        return CalendarEventForm(eventID: nil, title: "", start: start, end: end, calendarID: calendarID, readOnly: false)
    }

    package func withTimes(startMinutes: Int, endMinutes: Int, calendar: Calendar) -> CalendarEventForm {
        let date = calendar.startOfDay(for: start)
        var f = self
        f.start = Self.time(startMinutes, on: date, calendar: calendar)
        let endDate = endMinutes < startMinutes ? calendar.date(byAdding: .day, value: 1, to: date) ?? date : date
        f.end = Self.time(endMinutes, on: endDate, calendar: calendar)
        return f
    }

    package var canSave: Bool {
        !readOnly && calendarID != nil && CalendarEventText.clean(title) != nil && end > start
    }

    private static func time(_ minutes: Int, on date: Date, calendar: Calendar) -> Date {
        let hourMinutes = Int(Timing.hour / Timing.minute)
        return calendar.date(
            bySettingHour: minutes / hourMinutes,
            minute: minutes % hourMinutes,
            second: 0,
            of: date
        ) ?? date
    }
}

package enum CalendarEventText {
    package static func clean(_ raw: String) -> String? {
        let joined = String(raw.map { $0.isNewline ? " " : $0 })
        let trimmed = joined.trimmingCharacters(in: .whitespacesAndNewlines)
        let cut = String(trimmed.prefix(Limits.blockTitleMax)).trimmingCharacters(in: .whitespaces)
        return cut.isEmpty ? nil : cut
    }
}
