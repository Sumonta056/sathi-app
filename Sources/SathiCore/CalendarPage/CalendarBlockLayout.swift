import Foundation

package enum CalendarBlockLayout {
    package static func place(_ blocks: [CalendarBlock], within column: DateInterval) -> [CalendarPlacedBlock] {
        let cut = blocks.filter { !$0.isAllDay }.compactMap { b -> (CalendarBlock, DateInterval)? in
            let i = b.interval
            if i.duration == 0 { return column.start <= i.start && i.start < column.end ? (b, i) : nil }
            let start = max(i.start, column.start)
            let end = min(i.end, column.end)
            return start < end ? (b, DateInterval(start: start, end: end)) : nil
        }
        return lay(cut)
    }

    package static func place(_ blocks: [CalendarBlock]) -> [CalendarPlacedBlock] {
        lay(blocks.filter { !$0.isAllDay }.map { ($0, $0.interval) })
    }

    private struct Group {
        var start: Date
        var depth: Int
        var laneEnds: [Date]
        var members: [Int]
    }

    private static let window = TimeInterval(Limits.calendarSideBySideMinutes) * Timing.minute

    private static func lay(_ items: [(CalendarBlock, DateInterval)]) -> [CalendarPlacedBlock] {
        let backdrops = items.filter { $0.0.style == .away }.map {
            CalendarPlacedBlock(block: $0.0, span: $0.1, lane: 0, lanes: 1, isBackdrop: true)
        }
        let sorted = items.filter { $0.0.style != .away }.sorted {
            $0.1.start != $1.1.start ? $0.1.start < $1.1.start : $0.1.end > $1.1.end
        }
        var placed: [CalendarPlacedBlock] = []
        var groups: [Group] = []
        for (block, span) in sorted {
            let open = Set(placed.indices.filter { placed[$0].span.end > span.start })
            if let g = groups.lastIndex(where: { joins(span, $0, open: open) }) {
                let lane = groups[g].laneEnds.firstIndex { $0 <= span.start } ?? groups[g].laneEnds.count
                if lane == groups[g].laneEnds.count { groups[g].laneEnds.append(span.end) } else { groups[g].laneEnds[lane] = span.end }
                groups[g].members.append(placed.count)
                placed.append(CalendarPlacedBlock(block: block, span: span, lane: lane, lanes: 1, depth: groups[g].depth))
            } else {
                let top = open.map { placed[$0].depth }.max()
                let depth = top.map { min($0 + 1, Limits.calendarCascadeMaxDepth) } ?? 0
                groups.append(Group(start: span.start, depth: depth, laneEnds: [span.end], members: [placed.count]))
                placed.append(CalendarPlacedBlock(block: block, span: span, lane: 0, lanes: 1, depth: depth))
            }
        }
        for group in groups {
            for i in group.members {
                placed[i].lanes = group.laneEnds.count
            }
        }
        return backdrops + placed
    }

    private static func joins(_ span: DateInterval, _ group: Group, open: Set<Int>) -> Bool {
        span.start.timeIntervalSince(group.start) < window && group.members.contains(where: open.contains)
    }
}
