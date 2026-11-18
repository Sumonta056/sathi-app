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
                    dayTitle(day)
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

    private func dayTitle(_ day: DayKey) -> some View {
        let isToday = day == today
        return HStack(spacing: UIMetrics.calendarWeekHeaderGap) {
            Text(verbatim: Copywriter.calendarWeekday(day, calendar: calendar))
            number(day, isToday: isToday)
            Text(verbatim: Copywriter.calendarMonthShort(day, calendar: calendar))
        }
        .font(Typography.tracker(UIMetrics.calendarWeekHeaderFont, .bold))
        .foregroundStyle(isToday ? Night.tracker : Night.label)
        .lineLimit(1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Copywriter.calendarWeekDayHeader(day, calendar: calendar))
    }

    @ViewBuilder private func number(_ day: DayKey, isToday: Bool) -> some View {
        let text = Text(verbatim: Copywriter.calendarDayNumber(day, calendar: calendar))
        if isToday {
            text
                .foregroundStyle(Night.calendarTodayNumber)
                .frame(width: UIMetrics.calendarWeekTodayCircle, height: UIMetrics.calendarWeekTodayCircle)
                .background(Circle().fill(Night.tracker))
                .accessibilityIdentifier("calendar.week.todayNumber")
        } else {
            text.foregroundStyle(Night.text)
        }
    }

    private func label(_ text: String) -> some View {
        Text(verbatim: text)
            .font(Typography.tracker(UIMetrics.calendarWeekLabelFont, .bold))
            .tracking(UIMetrics.calendarWeekLabelTracking)
            .foregroundStyle(Night.faint)
            .lineLimit(1)
    }
}
