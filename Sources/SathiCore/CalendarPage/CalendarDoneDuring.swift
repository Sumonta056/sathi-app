import Foundation

enum CalendarDoneDuring {
    private static let lead = TimeInterval(Limits.calendarHostLeadMinutes) * Timing.minute

    static func fits(_ child: DateInterval, in host: DateInterval) -> Bool {
        guard child.duration > 0, child.start >= host.start.addingTimeInterval(-lead) else { return false }
        let inside = min(child.end, host.end).timeIntervalSince(max(child.start, host.start))
        return inside > 0 && inside >= child.duration * Limits.calendarHostShare
    }

    static func link(_ day: [CalendarLaidBlock]) -> [CalendarLaidBlock] {
        let all = day.flatMap { [$0] + $0.hidden }
        let events = all.filter(isHost).sorted { CalendarBlockLayout.precedes($0.rounded, $1.rounded) }
        var hosts: [String: String] = [:]
        for a in all where isChild(a) {
            if let e = events.first(where: { fits(a.rounded, in: $0.rounded) }) { hosts[a.id] = e.id }
        }
        var counts: [String: Int] = [:]
        for e in hosts.values {
            counts[e, default: 0] += 1
        }
        func mark(_ b: CalendarLaidBlock) -> CalendarLaidBlock {
            var b = b
            b.doneDuring = hosts[b.id]
            b.doneDuringCount = counts[b.id] ?? 0
            b.hidden = b.hidden.map(mark)
            return b
        }
        return day.map(mark)
    }

    private static func isHost(_ b: CalendarLaidBlock) -> Bool {
        guard b.block.style != .away, case .event = b.block.source else { return false }
        return true
    }

    private static func isChild(_ b: CalendarLaidBlock) -> Bool {
        guard b.block.style != .away, case .activity = b.block.source else { return false }
        return true
    }
}
