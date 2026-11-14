import Foundation

package struct CalendarPageData: Equatable, Sendable {
    package var range: CalendarPageRange
    package var allDay: [CalendarBlock]
    package var blocks: [CalendarBlock]
    package var stats: CalendarPageStats
    package var monthCells: [[CalendarMonthCell]]
}

extension Engine {
    package func calendarPage(_ range: CalendarPageRange) -> CalendarPageData {
        let readable = calendarAccess == .allowed ? calendarWriter.readableCalendars() : []
        let events = pageEvents(range, calendars: shownCalendars(readable))
        calendarPageEventsByID = Dictionary(events.map { ($0.id, $0) }) { first, _ in first }
        let tracks = data.prefs.tracker.isOn
        let rows = tracks ? pageActivities(range.interval) : []
        let running = tracks ? pageRunning(range.interval) : nil
        let all = CalendarBlockBuilder.blocks(
            events: events,
            activities: rows,
            running: running,
            colors: Dictionary(readable.map { ($0.id, $0.colorHex) }) { first, _ in first },
            joins: range.kind != .day
        )
        let tracked = rows + (running.map { [$0] } ?? [])
        let cells = range.kind == .month
            ? CalendarMonthCell.cells(
                range: range, blocks: all, activities: tracked,
                today: CalendarPageDay.key(holding: clock.now, calendar: calendar), calendar: calendar
            )
            : []
        return CalendarPageData(
            range: range,
            allDay: all.filter(\.isAllDay),
            blocks: all.filter { !$0.isAllDay },
            stats: CalendarPageStats.make(events: events, activities: tracked, interval: range.interval),
            monthCells: cells
        )
    }

    private func pageEvents(_ range: CalendarPageRange, calendars: [CalendarChoice]) -> [CalendarEventInfo] {
        guard !calendars.isEmpty else { return [] }
        let read = calendarWriter.events(from: range.interval.start, to: range.interval.end, calendarIDs: calendars.map(\.id))
        var seen = Set<String>()
        return read.filter { seen.insert(EventRules.key($0)).inserted }
    }

    private func pageActivities(_ interval: DateInterval) -> [Activity] {
        var months: [MonthKey] = []
        var d = calendar.startOfDay(for: interval.start)
        while d < interval.end {
            let key = MonthKey(d, calendar: calendar)
            if !months.contains(key) { months.append(key) }
            d = calendar.nextDay(after: d)
        }
        let runningID = data.live.tracker.running?.id
        return months.flatMap { activityStore.month($0).items }
            .filter { $0.id != runningID && $0.start < interval.end && $0.end > interval.start }
            .sorted { $0.start < $1.start }
    }

    private func pageRunning(_ interval: DateInterval) -> Activity? {
        guard let r = data.live.tracker.running else { return nil }
        let a = r.activity(until: max(r.start, clock.now))
        return a.start < interval.end && a.end >= interval.start ? a : nil
    }
}
