import Foundation

package enum CalendarSplitLanes {
    private static let window = TimeInterval(Limits.calendarSideBySideMinutes) * Timing.minute

    package static func arrange(_ items: [CalendarLaidBlock]) -> [CalendarLaidBlock] {
        var shown: [CalendarLaidBlock] = []
        for item in items.sorted(by: { CalendarBlockLayout.precedes($0.span, $1.span) }) {
            let over = shown.indices.filter { overlaps(shown[$0].span, item.span) }
            let near = over.filter { item.span.start.timeIntervalSince(shown[$0].span.start) < window }
            if over.isEmpty {
                shown.append(item)
            } else if let depth = near.map({ shown[$0].depth }).max() {
                sideBySide(item, depth: depth, peers: over.filter { shown[$0].depth == depth }, in: &shown)
            } else {
                raise(item, over: over, in: &shown)
            }
        }
        return shown
    }

    static func overlaps(_ a: DateInterval, _ b: DateInterval) -> Bool {
        a.start < b.end && b.start < a.end
    }

    private static func sideBySide(_ item: CalendarLaidBlock, depth: Int, peers: [Int], in shown: inout [CalendarLaidBlock]) {
        let used = Set(peers.map { shown[$0].lane })
        guard let lane = (0 ..< Limits.calendarLanesMax).first(where: { !used.contains($0) }) else {
            let first = peers.first { shown[$0].lane == 0 } ?? peers[0]
            shown[first].hidden.append(item)
            return
        }
        var x = item
        x.lane = lane
        x.depth = depth
        x.lanes = Limits.calendarLanesMax
        for p in peers {
            shown[p].lanes = Limits.calendarLanesMax
        }
        shown.append(x)
    }

    private static func raise(_ item: CalendarLaidBlock, over: [Int], in shown: inout [CalendarLaidBlock]) {
        let top = over.map { shown[$0].depth }.max() ?? 0
        guard top < Limits.calendarCascadeMaxDepth else {
            let deepest = over.last { shown[$0].depth == top } ?? over[0]
            shown[deepest].hidden.append(item)
            return
        }
        var x = item
        x.depth = top + 1
        shown.append(x)
    }
}
