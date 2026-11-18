import Foundation

package struct CalendarPageData: Equatable, Sendable {
    package var range: CalendarPageRange
    package var allDay: [CalendarBlock]
    package var blocks: [CalendarBlock]
    package var stats: CalendarPageStats
    package var monthCells: [[CalendarMonthCell]]
    package var texts: [String: CalendarBlockText]
    package var placed: [DayKey: [CalendarPlacedBlock]] = [:]
    package var placedMinimumMinutes: Double = 0
    package var placedNarrow: Set<CalendarLaneShape> = []
    package var grid: CalendarGridLayout?

    package var shownIDs: Set<String> {
        Set(blocks.map(\.id)).union(placed.values.joined().flatMap { [$0] + $0.children + $0.hidden }.map(\.block.id))
    }
}

package struct CalendarBlockText: Equatable, Sendable {
    package var time: String
    package var spoken: String

    package init(time: String, spoken: String) {
        self.time = time
        self.spoken = spoken
    }
}

extension Engine {
    package func calendarPage(
        _ range: CalendarPageRange,
        minimumMinutes: Double = 0,
        narrow: Set<CalendarLaneShape> = []
    ) -> CalendarPageData {
        let read = pageRead(range)
        let readable = read.readable
        let events = read.events
        let tracks = data.prefs.tracker.isOn
        let rows = tracks ? pageActivities(range.interval) : []
        let running = tracks ? pageRunning(range.interval) : nil
        let base = CalendarBlockBuilder.blocks(
            events: events,
            activities: rows,
            running: running,
            colors: Dictionary(readable.map { ($0.id, $0.colorHex) }) { first, _ in first },
            joins: range.kind != .day
        )
        let all = base + calendarTodoBlocks(range)
        let tracked = rows + (running.map { [$0] } ?? [])
        let cells = range.kind == .month
            ? CalendarMonthCell.cells(
                range: range, blocks: all, activities: tracked,
                today: CalendarPageDay.key(holding: clock.now, calendar: calendar), calendar: calendar
            )
            : []
        let timed = all.filter { !$0.isAllDay }
        let laid = range.kind == .month ? [:] : placed(timed, days: range.days, minimumMinutes: minimumMinutes, narrow: narrow)
        let groups = laid.values.joined().flatMap { [$0] + $0.children + $0.hidden }.map(\.block).filter { $0.group != nil }
        return CalendarPageData(
            range: range,
            allDay: all.filter(\.isAllDay),
            blocks: timed,
            stats: CalendarPageStats.make(events: events, activities: tracked, interval: range.interval),
            monthCells: cells,
            texts: Dictionary((all + groups).map { ($0.id, text(of: $0)) }) { first, _ in first },
            placed: laid,
            placedMinimumMinutes: minimumMinutes,
            placedNarrow: narrow
        )
    }

    private func placed(
        _ blocks: [CalendarBlock], days: [DayKey], minimumMinutes: Double, narrow: Set<CalendarLaneShape>
    ) -> [DayKey: [CalendarPlacedBlock]] {
        Dictionary(days.map { key in
            let column = CalendarPageDay.interval(of: key, calendar: calendar)
            return (key, CalendarBlockLayout.place(blocks, within: column, minimumMinutes: minimumMinutes, narrow: narrow))
        }) { first, _ in first }
    }

    private func text(of b: CalendarBlock) -> CalendarBlockText {
        let i = b.interval
        return CalendarBlockText(
            time: Fmt.shortRange(i.start, i.end, calendar: calendar),
            spoken: Copywriter.calendarBlockSpoken(b.title, i.start, i.end, calendar: calendar)
        )
    }

    private func pageRead(_ range: CalendarPageRange) -> CalendarPageRead {
        let key = CalendarPageReadKey(
            interval: range.interval, stores: storeRevision,
            hidden: data.prefs.calendarPage.hiddenCalendarIDs, access: calendarAccess
        )
        if let cached = calendarPageRead, cached.key == key { return cached }
        let readable = calendarAccess == .allowed ? calendarWriter.readableCalendars() : []
        let read = CalendarPageRead(key: key, readable: readable, events: pageEvents(range, calendars: shownCalendars(readable)))
        calendarPageRead = read
        calendarPageEventsByID = Dictionary(read.events.map { ($0.id, $0) }) { first, _ in first }
        return read
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
