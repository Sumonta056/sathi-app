import Foundation

package struct CalendarPlacedBlock: Equatable {
    package var block: CalendarBlock
    package var lane: Int
    package var lanes: Int
}

package enum CalendarBlockLayout {
    package static func place(_ blocks: [CalendarBlock]) -> [CalendarPlacedBlock] {
        let sorted = blocks.filter { !$0.isAllDay }.sorted {
            ($0.interval.start, $0.interval.end) < ($1.interval.start, $1.interval.end)
        }
        var result: [CalendarPlacedBlock] = []
        var cluster: [CalendarPlacedBlock] = []
        var laneEnds: [Date] = []
        var clusterEnd = Date.distantPast
        for block in sorted {
            if block.interval.start >= clusterEnd {
                result += finish(cluster, lanes: laneEnds.count)
                cluster = []
                laneEnds = []
            }
            let lane = laneEnds.firstIndex { $0 <= block.interval.start } ?? laneEnds.count
            if lane == laneEnds.count { laneEnds.append(block.interval.end) } else { laneEnds[lane] = block.interval.end }
            clusterEnd = cluster.isEmpty ? block.interval.end : max(clusterEnd, block.interval.end)
            cluster.append(CalendarPlacedBlock(block: block, lane: lane, lanes: 1))
        }
        return result + finish(cluster, lanes: laneEnds.count)
    }

    private static func finish(_ cluster: [CalendarPlacedBlock], lanes: Int) -> [CalendarPlacedBlock] {
        cluster.map { CalendarPlacedBlock(block: $0.block, lane: $0.lane, lanes: lanes) }
    }
}
