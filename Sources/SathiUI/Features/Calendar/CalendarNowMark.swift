import SathiCore
import SwiftUI

enum CalendarNowMark {
    static func y(_ grid: CalendarGridLayout, now: Date, day: DayKey, calendar: Calendar) -> CGFloat {
        CGFloat(grid.nowY(now, minute: CalendarSplitClock.minute(now, day: day, calendar: calendar), day: day))
    }

    static func pillY(_ y: CGFloat, gridHeight: CGFloat) -> CGFloat {
        let half = UIMetrics.calendarNowPillHeight / 2
        return min(max(y, half), max(half, gridHeight - half))
    }

    static func hidesLabel(rowTop: CGFloat, pillY: CGFloat) -> Bool {
        let top = rowTop + UIMetrics.calendarRailLabelTop
        let half = UIMetrics.calendarNowPillHeight / 2
        return top < pillY + half && pillY - half < top + UIMetrics.calendarNowPillHeight
    }
}
