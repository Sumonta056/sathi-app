import SathiCore
import SwiftUI

struct CalendarSplitMeasure: Equatable {
    let column: CGFloat
    let kind: ReportRange
}

enum CalendarSplitMetrics {
    static func metrics(kind: ReportRange, rowMinutes: Int, narrow: Bool) -> CalendarLayoutMetrics {
        let perMinute = Double(UIMetrics.calendarHourHeight(rowMinutes: rowMinutes)) / Double(Limits.minutesPerHour)
        let isDay = kind == .day
        let least = isDay ? UIMetrics.calendarDayCardMinHeight
            : narrow ? UIMetrics.calendarWeekNarrowMinHeight : UIMetrics.calendarWeekBlockMinHeight
        return CalendarLayoutMetrics(
            pointsPerMinute: perMinute,
            minHeight: least,
            awayMinHeight: isDay ? UIMetrics.calendarDayAwayMinHeight : least,
            compactHeight: isDay ? UIMetrics.calendarDayCompactMinHeight : nil,
            gap: isDay ? UIMetrics.calendarDayBlockGap : UIMetrics.calendarWeekBlockGap,
            titleRoom: UIMetrics.calendarTitleRoom,
            foldHeight: UIMetrics.calendarFoldHeight,
            foldsNights: kind == .week
        )
    }

    static func actualWidth(column: CGFloat, kind: ReportRange) -> CGFloat {
        let gutter = kind == .day ? UIMetrics.calendarDayLinkGutter : 0
        return max(0, column - gutter) * UIMetrics.calendarActualShare
    }

    static func narrow(_ m: CalendarSplitMeasure, current: Bool) -> Bool {
        m.kind == .week && m.column > 0 ? isNarrow(column: m.column, kind: .week) : current
    }

    static func isNarrow(column: CGFloat, kind: ReportRange) -> Bool {
        kind == .week && actualWidth(column: column, kind: kind) < UIMetrics.calendarNarrowActualWidth
    }
}
