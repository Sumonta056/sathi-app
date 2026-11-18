import SathiCore
import SwiftUI

struct CalendarWeekHeaders: View {
    let days: [DayKey]
    let today: DayKey
    let calendar: Calendar
    let column: CGFloat

    var body: some View {
        let halves = CalendarSplitGeometry.halves(column: column, kind: .week)
        HStack(spacing: 0) {
            Color.clear.frame(width: UIMetrics.calendarHourLabelWidth)
            ForEach(days, id: \.self) { day in
                VStack(spacing: 0) {
                    Text(verbatim: Copywriter.calendarWeekDayHeader(day, calendar: calendar))
                        .font(Typography.tracker(UIMetrics.calendarWeekHeaderFont, .bold))
                        .foregroundStyle(day == today ? Night.tracker : Night.text)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, minHeight: UIMetrics.calendarWeekHeaderHeight, maxHeight: UIMetrics.calendarWeekHeaderHeight)
                    HStack(spacing: 0) {
                        label(Copywriter.calendarActualLabel).frame(width: halves.actualWidth)
                        label(Copywriter.calendarPlanLabel).frame(width: halves.planWidth)
                    }
                    .frame(height: UIMetrics.calendarSplitLabelHeight)
                }
                .frame(width: column)
            }
        }
        .frame(height: Self.height)
    }

    static let height = UIMetrics.calendarWeekHeaderHeight + UIMetrics.calendarSplitLabelHeight

    private func label(_ text: String) -> some View {
        Text(verbatim: text)
            .font(Typography.tracker(UIMetrics.calendarWeekLabelFont, .bold))
            .tracking(UIMetrics.calendarWeekLabelTracking)
            .foregroundStyle(Night.faint)
            .lineLimit(1)
    }
}
