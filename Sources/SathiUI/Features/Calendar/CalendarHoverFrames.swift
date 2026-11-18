import SathiCore
import SwiftUI

struct CalendarHoverFrames {
    let day: DayKey
    let placed: [CalendarPlacedBlock]
    let math: CalendarGridMath
    let width: CGFloat
    let originX: CGFloat
    let prefersLeft: Bool

    func rect(_ p: CalendarPlacedBlock) -> CGRect {
        let indent = min(CGFloat(p.depth) * UIMetrics.calendarCascadeIndent, width / 2)
        let lane = CalendarNarrowLanes.laneWidth(depth: p.depth, lanes: p.lanes, inner: width)
        return CGRect(
            x: UIMetrics.calendarColumnInset + indent + lane * CGFloat(p.lane),
            y: math.y(for: p.displaySpan.start),
            width: p.isBackdrop ? width : max(0, lane - UIMetrics.calendarLaneGap),
            height: max(math.height(p.displaySpan), UIMetrics.calendarBarMinHeight)
        )
    }

    func target(_ p: CalendarPlacedBlock) -> CalendarHoverTarget {
        let local = localRect(p)
        return CalendarHoverTarget(
            day: day, placed: p, rect: local.offsetBy(dx: originX, dy: 0), radius: radius(p), prefersLeft: prefersLeft
        )
    }

    func stripe(at y: CGFloat) -> CalendarPlacedBlock? {
        placed.last { $0.isBackdrop && y >= math.y(for: $0.displaySpan.start) && y < math.y(for: $0.displaySpan.end) }
    }

    private func localRect(_ p: CalendarPlacedBlock) -> CGRect {
        if CalendarTodoLayer.holds(p) { return CalendarTodoLayer.pillRect(p, math: math, width: width) }
        guard let host = placed.first(where: { $0.children.contains { $0.block.id == p.block.id } }) else { return rect(p) }
        let outer = rect(host)
        return CGRect(
            x: outer.minX + UIMetrics.calendarChildInset, y: math.y(for: p.displaySpan.start),
            width: max(0, outer.width - 2 * UIMetrics.calendarChildInset),
            height: max(math.height(p.displaySpan), UIMetrics.calendarBarMinHeight)
        )
    }

    private func radius(_ p: CalendarPlacedBlock) -> CGFloat {
        if CalendarTodoLayer.holds(p) { return UIMetrics.calendarTodoPillHeight / 2 }
        return CalendarDayColumn.isEvent(p) ? UIMetrics.calendarEventRadius : UIMetrics.calendarBlockRadius
    }
}
