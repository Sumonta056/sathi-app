import Foundation

package enum ActivitySegmentKind: Equatable, Sendable {
    case work
    case away
    case notLogged
}

package struct ActivitySegment: Equatable, Identifiable, Sendable {
    package var kind: ActivitySegmentKind
    package var interval: DateInterval
    package var activity: Activity?

    package var id: String { "\(kind)-\(interval.start.timeIntervalSince1970)-\(activity?.id.raw.uuidString ?? "")" }
    package var length: TimeInterval { interval.duration }
}

package enum ActivityTimeline {
    package static func segments(_ day: ActivityDay) -> [ActivitySegment] {
        let hours = day.hours
        guard hours.duration > 0 else { return [] }
        var items = day.activities
        if let running = day.running, !items.contains(where: { $0.id == running.id }) { items.append(running) }
        items.sort { ($0.start, $0.end) < ($1.start, $1.end) }
        var cursor = hours.start
        var result: [ActivitySegment] = []
        for item in items {
            let start = max(item.start, cursor)
            let end = min(item.end, hours.end)
            guard end > start else { continue }
            if start > cursor { result.append(gap(cursor, start)) }
            let kind: ActivitySegmentKind = item.kind == .away ? .away : .work
            result.append(ActivitySegment(kind: kind, interval: DateInterval(start: start, end: end), activity: item))
            cursor = end
        }
        if cursor < hours.end { result.append(gap(cursor, hours.end)) }
        return result
    }

    private static func gap(_ start: Date, _ end: Date) -> ActivitySegment {
        ActivitySegment(kind: .notLogged, interval: DateInterval(start: start, end: end), activity: nil)
    }
}
