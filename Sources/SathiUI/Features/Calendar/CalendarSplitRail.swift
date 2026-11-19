import SathiCore
import SwiftUI

struct CalendarSplitRail: View {
    let grid: CalendarGridLayout
    let now: Date?
    let day: DayKey
    let calendar: Calendar

    var body: some View {
        let labels = Dictionary(CalendarSplitClock.labels(grid).map { ($0.row, $0.text) }) { first, _ in first }
        let pillY = pillY
        VStack(spacing: 0) {
            ForEach(Array(grid.rows.enumerated()), id: \.offset) { index, row in
                Text(verbatim: labels[index] ?? "")
                    .font(Typography.tracker(UIMetrics.calendarHourFont, .semibold))
                    .foregroundStyle(Night.faint)
                    .opacity(pillY.map { CalendarNowMark.hidesLabel(rowTop: CGFloat(row.top), pillY: $0) } == true ? 0 : 1)
                    .padding(.top, UIMetrics.calendarRailLabelTop)
                    .padding(.trailing, UIMetrics.calendarRailLabelTrailing)
                    .frame(width: UIMetrics.calendarHourLabelWidth, height: CGFloat(row.height), alignment: .topTrailing)
                    .id(index)
            }
        }
        .overlay(alignment: .topTrailing) {
            if let now, let pillY {
                CalendarNowPill(now: now, calendar: calendar)
                    .alignmentGuide(.top) { $0[VerticalAlignment.center] - pillY }
                    .padding(.trailing, UIMetrics.calendarNowPillTrailing)
            }
        }
    }

    private var pillY: CGFloat? {
        guard let now else { return nil }
        return CalendarNowMark.pillY(CalendarNowMark.y(grid, now: now, day: day, calendar: calendar), gridHeight: CGFloat(grid.height))
    }
}
