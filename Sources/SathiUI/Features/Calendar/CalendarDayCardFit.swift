import SwiftUI

enum CalendarDayCardFit {
    static func twoLineHeight(away: Bool) -> CGFloat {
        let p = away ? UIMetrics.calendarDayAwayPadding : UIMetrics.calendarDayCardPadding
        return p.top + p.bottom + UIMetrics.calendarDayTitleLine + UIMetrics.calendarDayLineGap + UIMetrics.calendarDayMetaLine
    }

    static func titleLines(height: CGFloat) -> Int {
        let p = UIMetrics.calendarDayCardPadding
        let room = height - p.top - p.bottom - UIMetrics.calendarDayMetaLine - UIMetrics.calendarDayLineGap
        let lines = Int((room / UIMetrics.calendarDayTitleLine).rounded(.down))
        return min(UIMetrics.calendarDayTitleLinesMax, max(1, lines))
    }
}
