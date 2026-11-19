import Foundation

package enum CalendarBlockBuilder {
    package static func blocks(
        events: [CalendarEventInfo],
        activities: [Activity],
        running: Activity?,
        colors: [String: UInt32],
        joins: Bool
    ) -> [CalendarBlock] {
        let finished = activities.filter { $0.id != running?.id }
        let all = finished + (running.map { [$0] } ?? [])
        let shown = CalendarTitleMatch.copies(events.filter { !hides($0, in: all) })
        let eventBlocks = shown.map { eventBlock($0.event, copies: $0.count, colors: colors) }
        let groups = joins ? CalendarDisplayJoin.groups(finished) : finished.map { [$0] }
        let activityBlocks = groups.map { activityBlock($0, running: false, events: events) }
        let runningBlock = running.map { [activityBlock([$0], running: true, events: events)] } ?? []
        return eventBlocks + activityBlocks + runningBlock
    }

    package static func hides(_ e: CalendarEventInfo, in activities: [Activity]) -> Bool {
        activities.contains { $0.eventID == e.id }
    }

    private static func eventBlock(_ e: CalendarEventInfo, copies: Int, colors: [String: UInt32]) -> CalendarBlock {
        CalendarBlock(
            id: EventRules.key(e),
            title: e.title,
            interval: DateInterval(start: e.start, end: max(e.start, e.end)),
            style: .event(colorHex: colors[e.calendarID] ?? 0),
            source: .event(e),
            isAllDay: e.isAllDay,
            activityIDs: [],
            copies: copies
        )
    }

    private static func activityBlock(_ rows: [Activity], running: Bool, events: [CalendarEventInfo]) -> CalendarBlock {
        let first = rows[0]
        let end = rows.map(\.end).max() ?? first.end
        return CalendarBlock(
            id: "a-" + first.id.raw.uuidString,
            title: first.kind == .away ? first.awayText : first.text,
            interval: DateInterval(start: first.start, end: max(first.start, end)),
            style: style(of: rows, events: events),
            source: .activity(first, running: running),
            isAllDay: false,
            activityIDs: rows.map(\.id)
        )
    }

    private static func style(of rows: [Activity], events: [CalendarEventInfo]) -> CalendarBlockStyle {
        let a = rows[0]
        if a.kind == .away { return .away }
        let joined = rows.contains { row in row.sourceEventID != nil || events.contains { CalendarTitleMatch.joins(row, $0) } }
        return joined ? .joined(category: a.category) : .activity(category: a.category)
    }
}
