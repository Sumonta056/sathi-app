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
        let eventBlocks = events.filter { !hides($0, in: all) }.map { eventBlock($0, colors: colors) }
        let groups = joins ? CalendarDisplayJoin.groups(finished) : finished.map { [$0] }
        let activityBlocks = groups.map { activityBlock($0, running: false) }
        let runningBlock = running.map { [activityBlock([$0], running: true)] } ?? []
        return eventBlocks + activityBlocks + runningBlock
    }

    package static func hides(_ e: CalendarEventInfo, in activities: [Activity]) -> Bool {
        activities.contains { $0.eventID == e.id } || EventRules.isLogged(e, in: activities)
    }

    private static func eventBlock(_ e: CalendarEventInfo, colors: [String: UInt32]) -> CalendarBlock {
        CalendarBlock(
            id: EventRules.key(e),
            title: e.title,
            interval: DateInterval(start: e.start, end: max(e.start, e.end)),
            style: .event(colorHex: colors[e.calendarID] ?? 0),
            source: .event(e),
            isAllDay: e.isAllDay,
            activityIDs: []
        )
    }

    private static func activityBlock(_ rows: [Activity], running: Bool) -> CalendarBlock {
        let first = rows[0]
        let end = rows.map(\.end).max() ?? first.end
        return CalendarBlock(
            id: "a-" + first.id.raw.uuidString,
            title: first.kind == .away ? first.awayText : first.text,
            interval: DateInterval(start: first.start, end: max(first.start, end)),
            style: style(of: first),
            source: .activity(first, running: running),
            isAllDay: false,
            activityIDs: rows.map(\.id)
        )
    }

    private static func style(of a: Activity) -> CalendarBlockStyle {
        if a.kind == .away { return .away }
        return a.sourceEventID == nil ? .activity(category: a.category) : .joined(category: a.category)
    }
}
