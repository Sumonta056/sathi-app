import Foundation

package struct TrackerHours: Sendable {
    package var prefs: TrackerPrefs
    package var calendar: Calendar

    package init(prefs: TrackerPrefs, calendar: Calendar) {
        self.prefs = prefs
        self.calendar = calendar
    }

    package func isTrackerDay(_ date: Date) -> Bool {
        prefs.days.isOn(date, calendar: calendar)
    }

    package func hours(on date: Date) -> DateInterval {
        let start = time(prefs.startMinutes, on: date)
        let end = time(prefs.endMinutes, on: date)
        return DateInterval(start: start, end: max(start, end))
    }

    package func isInside(_ date: Date) -> Bool {
        guard isTrackerDay(date) else { return false }
        let h = hours(on: date)
        return date >= h.start && date < h.end
    }

    package func nextStart(after date: Date) -> Date? {
        var day = calendar.startOfDay(for: date)
        for _ in 0 ... Limits.daysOffMaxAhead + Limits.daysPerWeek {
            let h = hours(on: day)
            if isTrackerDay(day), h.duration > 0, h.start > date { return h.start }
            day = calendar.nextDay(after: day)
        }
        return nil
    }

    package func clip(_ span: DateInterval) -> [DateInterval] {
        var parts: [DateInterval] = []
        var day = calendar.startOfDay(for: span.start)
        while day < span.end {
            let h = hours(on: day)
            let start = max(h.start, span.start)
            let end = min(h.end, span.end)
            if isTrackerDay(day), end > start { parts.append(DateInterval(start: start, end: end)) }
            day = calendar.nextDay(after: day)
        }
        return parts
    }

    private func time(_ minutes: Int, on date: Date) -> Date {
        let day = calendar.startOfDay(for: date)
        if minutes >= Limits.minutesPerDay { return calendar.nextDay(after: day) }
        return DayClock(calendar: calendar).at(minutes, on: day)
    }
}
