import Foundation
import SathiCore

enum ActivityLogRow: Equatable, Identifiable {
    case activity(Activity, running: Bool)
    case gap(DateInterval)

    var id: String {
        switch self {
        case let .activity(a, _): return a.id.raw.uuidString
        case let .gap(i): return "gap-\(i.start.timeIntervalSince1970)"
        }
    }
}

enum ActivityLogRows {
    static func make(_ day: ActivityDay, gaps: [DateInterval]? = nil) -> [ActivityLogRow] {
        var items = day.activities
        if let running = day.running, !items.contains(where: { $0.id == running.id }) { items.append(running) }
        let activities = items.map { (start: $0.start, row: ActivityLogRow.activity($0, running: $0.id == day.running?.id)) }
        let spans = gaps ?? ActivityGaps.spans(day, now: .distantFuture, isTrackerDay: true)
        let gapRows = spans.map { (start: $0.start, row: ActivityLogRow.gap($0)) }
        return (activities + gapRows).sorted { $0.start < $1.start }.map(\.row)
    }
}
