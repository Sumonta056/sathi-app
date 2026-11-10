import Foundation

package enum EventRules {
    package static func key(_ e: CalendarEventInfo) -> String {
        e.id + "@" + String(Int(e.start.wholeSecond.timeIntervalSince1970))
    }

    package static func isTimed(_ e: CalendarEventInfo) -> Bool {
        !e.isAllDay && !e.declined && e.end > e.start
    }

    package static func usable(
        _ events: [CalendarEventInfo],
        hours: TrackerHours,
        written: Set<String>,
        items: [Activity]
    ) -> [CalendarEventInfo] {
        events
            .filter { isTimed($0) && !written.contains($0.id) && hours.isInside($0.start) && !isTimeBlock($0, items: items) }
            .sorted { $0.start < $1.start }
    }

    package static func isLogged(_ e: CalendarEventInfo, in items: [Activity]) -> Bool {
        items.contains { $0.sourceEventID == e.id && $0.start >= e.start.wholeSecond && $0.start < e.end }
    }

    package static func firstStays(_ events: [CalendarEventInfo]) -> [CalendarEventInfo] {
        var kept: [CalendarEventInfo] = []
        for e in events.sorted(by: { $0.start < $1.start }) where kept.last.map({ e.start >= $0.end }) ?? true {
            kept.append(e)
        }
        return kept
    }

    private static func isTimeBlock(_ e: CalendarEventInfo, items: [Activity]) -> Bool {
        items.contains { $0.kind == .timeBlock && $0.text == e.title && $0.start == e.start.wholeSecond }
    }
}
