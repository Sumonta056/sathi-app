import SwiftUI

enum CalendarBlockFit {
    static func border(selected: Bool) -> CGFloat {
        selected ? UIMetrics.calendarSelectedBorder : UIMetrics.cardBorder
    }

    static func showsText(height: CGFloat) -> Bool { height >= UIMetrics.calendarBlockMinTextHeight }

    static func showsTimeRange(height: CGFloat) -> Bool { height >= UIMetrics.calendarTimeRangeMinHeight }

    static func titleLines(height: CGFloat) -> Int {
        let padding = UIMetrics.calendarBlockPadding.top + UIMetrics.calendarBlockPadding.bottom
        let time = showsTimeRange(height: height) ? UIMetrics.calendarTimeLineHeight : 0
        let room = (height - padding - time) / UIMetrics.calendarTitleLineHeight
        return min(UIMetrics.calendarTitleLinesMax, max(1, Int(room.rounded(.down))))
    }
}
