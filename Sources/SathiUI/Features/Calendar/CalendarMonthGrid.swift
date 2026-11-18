import SathiCore
import SwiftUI

struct CalendarMonthGrid: View {
    let cells: [[CalendarMonthCell]]
    @Binding var range: CalendarPageRange
    let calendar: Calendar
    var categories: [ActivityCategory] = []

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.calendarGridRadius, style: .continuous)
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(cells.first?.map(\.day) ?? [], id: \.self) { day in
                    Text(verbatim: Copywriter.calendarWeekday(day, calendar: calendar))
                        .font(Typography.tracker(UIMetrics.calendarDayHeaderFont, .bold))
                        .foregroundStyle(Night.muted)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: UIMetrics.calendarDayHeaderHeight)
            ForEach(Array(cells.enumerated()), id: \.offset) { _, week in
                Night.divider.frame(height: UIMetrics.calendarLine)
                HStack(spacing: 0) {
                    ForEach(Array(week.enumerated()), id: \.offset) { index, cell in
                        if index > 0 { Night.divider.frame(width: UIMetrics.calendarLine) }
                        CalendarMonthCellView(cell: cell, calendar: calendar, categories: categories) { open(cell.day) }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .background(shape.fill(Night.card))
        .clipShape(shape)
        .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
    }

    private func open(_ day: DayKey) {
        range = .containing(day: day, kind: .day, calendar: calendar, weekDays: range.weekDays)
    }
}
