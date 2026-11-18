import Foundation

package enum CalendarBlockHost {
    private static let lead = TimeInterval(Limits.calendarHostLeadMinutes) * Timing.minute

    package static func hosts(_ items: [(block: CalendarBlock, span: DateInterval)]) -> [String: String] {
        let events = items.filter { isHost($0.block) }.sorted { CalendarBlockLayout.precedes($0.span, $1.span) }
        var result: [String: String] = [:]
        for item in items where isChild(item.block) {
            if let host = events.first(where: { fits(item.span, in: $0.span) }) { result[item.block.id] = host.block.id }
        }
        return result
    }

    private static func fits(_ child: DateInterval, in host: DateInterval) -> Bool {
        guard child.duration > 0, child.start >= host.start.addingTimeInterval(-lead) else { return false }
        let overlap = min(child.end, host.end).timeIntervalSince(max(child.start, host.start))
        return overlap > 0 && overlap >= child.duration * Limits.calendarHostShare
    }

    private static func isHost(_ b: CalendarBlock) -> Bool {
        guard b.style != .away, case .event = b.source else { return false }
        return true
    }

    private static func isChild(_ b: CalendarBlock) -> Bool {
        guard b.style != .away, case .activity = b.source else { return false }
        return true
    }
}
