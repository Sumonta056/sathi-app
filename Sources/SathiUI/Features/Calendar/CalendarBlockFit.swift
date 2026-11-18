import SwiftUI

enum CalendarBlockFit {
    static func border(selected: Bool) -> CGFloat {
        selected ? UIMetrics.calendarSelectedBorder : UIMetrics.cardBorder
    }

    static func showsText(height: CGFloat) -> Bool { fits(height, UIMetrics.calendarBlockMinTextHeight) }

    static func showsTimeRange(height: CGFloat) -> Bool { fits(height, UIMetrics.calendarTimeRangeMinHeight) }

    static func titleLines(height: CGFloat) -> Int {
        let padding = UIMetrics.calendarBlockPadding.top + UIMetrics.calendarBlockPadding.bottom
        let time = showsTimeRange(height: height) ? UIMetrics.calendarTimeLineHeight : 0
        let room = (height + UIMetrics.calendarFitTolerance - padding - time) / UIMetrics.calendarTitleLineHeight
        return min(UIMetrics.calendarTitleLinesMax, max(1, Int(room.rounded(.down))))
    }

    static func activityTitleLines(height: CGFloat, width: CGFloat, below: CGFloat = 0) -> Int {
        guard CalendarNarrowLanes.isNarrow(width), showsTimeRange(height: height) else { return 1 }
        return min(UIMetrics.calendarNarrowTitleLinesMax, titleLines(height: height - below))
    }

    private static func fits(_ height: CGFloat, _ needed: CGFloat) -> Bool {
        height + UIMetrics.calendarFitTolerance >= needed
    }
}
