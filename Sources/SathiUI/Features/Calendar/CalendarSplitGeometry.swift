import SathiCore
import SwiftUI

struct CalendarSplitHalves: Equatable {
    let actualX: CGFloat
    let actualWidth: CGFloat
    let planX: CGFloat
    let planWidth: CGFloat
}

enum CalendarSplitGeometry {
    static func halves(column: CGFloat, kind: ReportRange) -> CalendarSplitHalves {
        let actual = CalendarSplitMetrics.actualWidth(column: column, kind: kind)
        let gutter = kind == .day ? UIMetrics.calendarDayLinkGutter : 0
        let planX = actual + gutter
        return CalendarSplitHalves(actualX: 0, actualWidth: actual, planX: planX, planWidth: max(0, column - planX))
    }

    static func rect(_ laid: CalendarLaidBlock, halves: CalendarSplitHalves) -> CGRect {
        let origin = laid.half == .actual ? halves.actualX : halves.planX
        let width = laid.half == .actual ? halves.actualWidth : halves.planWidth
        let indent = min(CGFloat(laid.depth) * UIMetrics.calendarCascadeIndent, width / 2)
        let lane = (width - indent) / CGFloat(max(1, laid.lanes))
        return CGRect(
            x: origin + indent + lane * CGFloat(laid.lane),
            y: laid.top,
            width: max(0, lane - UIMetrics.calendarLaneGap),
            height: max(0, laid.bottom - laid.top)
        )
    }

    static func todoRect(_ laid: CalendarLaidBlock, halves: CalendarSplitHalves) -> CGRect {
        let pill = halves.planWidth * UIMetrics.calendarTodoPillWidthShare
        let height = UIMetrics.calendarTodoPillHeight
        return CGRect(x: halves.planX + halves.planWidth - pill, y: laid.top - height / 2, width: pill, height: height)
    }

    static func dueLine(top: Double, halves: CalendarSplitHalves) -> CGRect {
        let width = UIMetrics.calendarTodoLineWidth
        return CGRect(x: halves.planX, y: top - width / 2, width: halves.planWidth, height: width)
    }

    static func hoverRect(_ laid: CalendarLaidBlock, halves: CalendarSplitHalves) -> CGRect {
        laid.isTodo ? todoRect(laid, halves: halves) : rect(laid, halves: halves)
    }
}
