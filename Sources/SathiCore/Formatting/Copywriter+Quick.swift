import Foundation

extension Copywriter {
    package static let quickNoSnooze = "No snoozes left. It stays until you tap Done."

    package static func quickEyebrow(due: Date, calendar: Calendar) -> String {
        "QUICK REMINDER · " + quickClock(due, calendar: calendar)
    }

    package static func quickSetAt(_ created: Date, calendar: Calendar) -> String {
        "You set this at " + quickClock(created, calendar: calendar) + "."
    }

    package static func quickComesBack(text: String, at date: Date, calendar: Calendar) -> String {
        "“\(quickCut(text))” comes back at " + quickClock(date, calendar: calendar)
    }

    package static func quickWhen(_ fire: Date, now: Date, showing: Bool, calendar: Calendar) -> String {
        if showing { return "Showing now" }
        if calendar.isDate(fire, inSameDayAs: now) { return "in " + Fmt.short(fire.timeIntervalSince(now)) }
        return "Tomorrow"
    }

    package static func quickPreview(_ date: Date, now: Date, calendar: Calendar) -> String {
        let day = calendar.isDate(date, inSameDayAs: now) ? "Today" : "Tomorrow"
        return day + " at " + quickClock(date, calendar: calendar)
    }

    package static func quickClock(_ date: Date, calendar: Calendar) -> String {
        var style = Date.FormatStyle(date: .omitted, time: .shortened)
        style.timeZone = calendar.timeZone
        return date.formatted(style)
    }

    private static func quickCut(_ text: String) -> String {
        text.count > Limits.quickNoteTextMax ? String(text.prefix(Limits.quickNoteTextMax)) + "…" : text
    }
}
