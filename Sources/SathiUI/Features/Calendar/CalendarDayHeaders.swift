import SathiCore
import SwiftUI

struct CalendarDayHeaders: View {
    let days: [DayKey]
    let today: DayKey
    let calendar: Calendar

    var body: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: UIMetrics.calendarHourLabelWidth)
            ForEach(days, id: \.self) { day in
                HStack(spacing: UIMetrics.calendarHeaderGap) {
                    Text(verbatim: Copywriter.calendarWeekday(day, calendar: calendar))
                        .foregroundStyle(day == today ? Night.tracker : Night.muted)
                    number(day)
                }
                .font(Typography.tracker(UIMetrics.calendarDayHeaderFont, .bold))
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: UIMetrics.calendarDayHeaderHeight)
    }

    @ViewBuilder private func number(_ day: DayKey) -> some View {
        let text = Text(verbatim: Copywriter.calendarDayNumber(day, calendar: calendar))
        if day == today {
            text.foregroundStyle(Night.trackerOnAccent)
                .frame(width: UIMetrics.calendarDayCircle, height: UIMetrics.calendarDayCircle)
                .background(Circle().fill(Night.tracker))
        } else {
            text.foregroundStyle(Night.text)
        }
    }
}
