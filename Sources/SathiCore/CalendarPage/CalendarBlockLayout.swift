import Foundation

package struct CalendarPlacedBlock: Equatable {
    package var block: CalendarBlock
    package var span: DateInterval
    package var lane: Int
    package var lanes: Int

    package init(block: CalendarBlock, span: DateInterval? = nil, lane: Int, lanes: Int) {
        self.block = block
        self.span = span ?? block.interval
        self.lane = lane
        self.lanes = lanes
    }
}

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

    private static func lay(_ items: [(CalendarBlock, DateInterval)]) -> [CalendarPlacedBlock] {
        let sorted = items.sorted { ($0.1.start, $0.1.end) < ($1.1.start, $1.1.end) }
        var result: [CalendarPlacedBlock] = []
        var cluster: [CalendarPlacedBlock] = []
        var laneEnds: [Date] = []
        var clusterEnd = Date.distantPast
        for (block, span) in sorted {
            if span.start >= clusterEnd {
                result += finish(cluster, lanes: laneEnds.count)
                cluster = []
                laneEnds = []
            }
            let lane = laneEnds.firstIndex { $0 <= span.start } ?? laneEnds.count
            if lane == laneEnds.count { laneEnds.append(span.end) } else { laneEnds[lane] = span.end }
            clusterEnd = cluster.isEmpty ? span.end : max(clusterEnd, span.end)
            cluster.append(CalendarPlacedBlock(block: block, span: span, lane: lane, lanes: 1))
        }
        return result + finish(cluster, lanes: laneEnds.count)
    }

    private static func finish(_ cluster: [CalendarPlacedBlock], lanes: Int) -> [CalendarPlacedBlock] {
        cluster.map { CalendarPlacedBlock(block: $0.block, span: $0.span, lane: $0.lane, lanes: lanes) }
    }
}
