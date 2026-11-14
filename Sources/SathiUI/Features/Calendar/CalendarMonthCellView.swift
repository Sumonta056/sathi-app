import SathiCore
import SwiftUI

struct CalendarMonthCellView: View {
    let cell: CalendarMonthCell
    let calendar: Calendar
    let categories: [ActivityCategory]
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            VStack(alignment: .leading, spacing: UIMetrics.calendarChipGap) {
                HStack(alignment: .center) {
                    number
                    Spacer(minLength: 0)
                    if cell.tracked > 0 {
                        Text(verbatim: Copywriter.activitiesLength(cell.tracked))
                            .font(Typography.tracker(UIMetrics.calendarMonthTrackedFont, .bold))
                            .foregroundStyle(Night.tracker)
                    }
                }
                ForEach(cell.chips) { CalendarChip(block: $0, categories: categories) }
                if cell.more > 0 {
                    Text(verbatim: Copywriter.calendarMore(cell.more))
                        .font(Typography.tracker(UIMetrics.calendarChipFont, .semibold))
                        .foregroundStyle(Night.muted)
                }
            }
            .padding(UIMetrics.calendarMonthPadding)
            .frame(maxWidth: .infinity, minHeight: UIMetrics.calendarMonthCellMinHeight, maxHeight: .infinity, alignment: .topLeading)
            .background(cell.isToday ? Night.trackerSelectedFill : .clear)
            .opacity(cell.inRange ? 1 : UIMetrics.calendarOutsideOpacity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("calendar.month." + cell.day.raw)
    }

    @ViewBuilder private var number: some View {
        let text = Text(verbatim: Copywriter.calendarDayNumber(cell.day, calendar: calendar))
            .font(Typography.tracker(UIMetrics.calendarMonthNumberFont, .bold))
        if cell.isToday {
            ZStack {
                Circle().fill(Night.tracker)
                text.foregroundStyle(Night.trackerOnAccent)
            }
            .frame(width: UIMetrics.calendarDayCircle, height: UIMetrics.calendarDayCircle)
            .accessibilityIdentifier("calendar.month.today")
        } else {
            text.foregroundStyle(Night.text)
        }
    }
}
