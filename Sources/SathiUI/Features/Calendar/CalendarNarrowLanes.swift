import SathiCore
import SwiftUI

enum CalendarNarrowLanes {
    static func laneWidth(depth: Int, lanes: Int, inner width: CGFloat) -> CGFloat {
        let indent = min(CGFloat(depth) * UIMetrics.calendarCascadeIndent, width / 2)
        return (width - indent) / CGFloat(max(1, lanes))
    }

    static func shapes(columnWidth: CGFloat) -> Set<CalendarLaneShape> {
        let inner = columnWidth - 2 * UIMetrics.calendarColumnInset
        guard inner > 0 else { return [] }
        let all = (0 ... Limits.calendarCascadeMaxDepth).flatMap { depth in
            (1 ... Limits.calendarLanesMax).map { CalendarLaneShape(depth: depth, lanes: $0) }
        }
        return Set(all.filter {
            laneWidth(depth: $0.depth, lanes: $0.lanes, inner: inner) - UIMetrics.calendarLaneGap < UIMetrics.calendarNarrowLaneWidth
        })
    }

    static func isNarrow(_ width: CGFloat) -> Bool {
        width < UIMetrics.calendarNarrowLaneWidth
    }
}
