import Foundation

package enum CalendarBlockNudge {
    package static func apply(_ placed: [CalendarPlacedBlock], minimumMinutes: Double) -> [CalendarPlacedBlock] {
        let least = max(0, minimumMinutes) * Timing.minute
        var result = placed
        let order = result.indices.filter { moves(result[$0]) }.sorted {
            result[$0].span.start != result[$1].span.start ? result[$0].span.start < result[$1].span.start : $0 < $1
        }
        for (k, i) in order.enumerated() {
            let floor = order.prefix(k).filter { pushes(result[$0], result[i]) }.map { result[$0].displaySpan.end }.max()
            let start = max(result[i].span.start, floor ?? result[i].span.start)
            fill(&result[i], start: start, least: least)
        }
        return result
    }

    private static func moves(_ p: CalendarPlacedBlock) -> Bool {
        if p.isBackdrop { return false }
        if case .todo = p.block.source { return false }
        return true
    }

    private static func pushes(_ above: CalendarPlacedBlock, _ below: CalendarPlacedBlock) -> Bool {
        above.depth == below.depth && above.span.end <= below.span.start && sharesWidth(above, below)
    }

    private static func sharesWidth(_ a: CalendarPlacedBlock, _ b: CalendarPlacedBlock) -> Bool {
        a.lane * b.lanes < (b.lane + 1) * a.lanes && b.lane * a.lanes < (a.lane + 1) * b.lanes
    }

    private static func fill(_ host: inout CalendarPlacedBlock, start: Date, least: TimeInterval) {
        let shift = start.timeIntervalSince(host.span.start)
        var cursor = start.addingTimeInterval(host.children.isEmpty ? 0 : least)
        for c in host.children.indices {
            let child = host.children[c].span
            let from = max(child.start.addingTimeInterval(shift), cursor)
            let to = from.addingTimeInterval(max(child.duration, least))
            host.children[c].displaySpan = DateInterval(start: from, end: to)
            cursor = to
        }
        let own = start.addingTimeInterval(max(host.span.duration, least))
        host.displaySpan = DateInterval(start: start, end: max(own, cursor))
    }
}
