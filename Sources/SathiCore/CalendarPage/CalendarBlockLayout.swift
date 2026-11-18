import Foundation

package enum CalendarBlockLayout {
    package typealias Item = (block: CalendarBlock, span: DateInterval)

    package static func place(
        _ blocks: [CalendarBlock],
        within column: DateInterval,
        minimumMinutes: Double = 0
    ) -> [CalendarPlacedBlock] {
        let cut = blocks.filter { !$0.isAllDay }.compactMap { b -> Item? in
            let i = b.interval
            if i.duration == 0 { return column.start <= i.start && i.start < column.end ? (b, i) : nil }
            let start = max(i.start, column.start)
            let end = min(i.end, column.end)
            return start < end ? (b, DateInterval(start: start, end: end)) : nil
        }
        return lay(cut, minimumMinutes: minimumMinutes)
    }

    package static func place(_ blocks: [CalendarBlock], minimumMinutes: Double = 0) -> [CalendarPlacedBlock] {
        lay(blocks.filter { !$0.isAllDay }.map { ($0, $0.interval) }, minimumMinutes: minimumMinutes)
    }

    static func precedes(_ a: DateInterval, _ b: DateInterval) -> Bool {
        a.start != b.start ? a.start < b.start : a.end > b.end
    }

    private struct Group {
        var start: Date
        var depth: Int
        var laneEnds: [Date]
        var members: [Int]

        func freeLane(at start: Date) -> Int? {
            if let lane = laneEnds.firstIndex(where: { $0 <= start }) { return lane }
            return laneEnds.count < Limits.calendarLanesMax ? laneEnds.count : nil
        }
    }

    private static let window = TimeInterval(Limits.calendarSideBySideMinutes) * Timing.minute

    private static func lay(_ items: [Item], minimumMinutes: Double) -> [CalendarPlacedBlock] {
        let hosts = CalendarBlockHost.hosts(items)
        let backdrops = items.filter { $0.block.style == .away }.map {
            CalendarPlacedBlock(block: $0.block, span: $0.span, lane: 0, lanes: 1, isBackdrop: true)
        }
        let todos = items.filter { isTodo($0.block) }.map { CalendarPlacedBlock(block: $0.block, span: $0.span, lane: 0, lanes: 1) }
        let top = items.filter { $0.block.style != .away && !isTodo($0.block) && hosts[$0.block.id] == nil }
            .sorted { precedes($0.span, $1.span) }
        let children = items.filter { hosts[$0.block.id] != nil }.sorted { precedes($0.span, $1.span) }
        let placed = stack(top).map { adopt($0, children, hosts: hosts) }
        return CalendarBlockNudge.apply(backdrops + placed, minimumMinutes: minimumMinutes) + todos
    }

    private static func isTodo(_ b: CalendarBlock) -> Bool {
        if case .todo = b.source { return true }
        return false
    }

    private static func stack(_ sorted: [Item]) -> [CalendarPlacedBlock] {
        var placed: [CalendarPlacedBlock] = []
        var groups: [Group] = []
        for (block, span) in sorted {
            let open = Set(placed.indices.filter { placed[$0].span.end > span.start })
            if let g = groups.lastIndex(where: { joins(span, $0, open: open) }) {
                guard let lane = groups[g].freeLane(at: span.start) else {
                    placed[groups[g].members[0]].hiddenCount += 1
                    continue
                }
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
        return placed
    }

    private static func adopt(_ host: CalendarPlacedBlock, _ items: [Item], hosts: [String: String]) -> CalendarPlacedBlock {
        var host = host
        host.children = items.filter { hosts[$0.block.id] == host.block.id }.map {
            var child = CalendarPlacedBlock(
                block: $0.block, span: $0.span, lane: host.lane, lanes: host.lanes, depth: host.depth, hostID: host.block.id
            )
            child.isRaised = false
            return child
        }
        return host
    }

    private static func joins(_ span: DateInterval, _ group: Group, open: Set<Int>) -> Bool {
        span.start.timeIntervalSince(group.start) < window && group.members.contains(where: open.contains)
    }
}
