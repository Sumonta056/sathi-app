import SathiCore
import SwiftUI

struct CalendarSplitRail: View {
    let grid: CalendarGridLayout

    var body: some View {
        let labels = Dictionary(CalendarSplitClock.labels(grid).map { ($0.row, $0.text) }) { first, _ in first }
        VStack(spacing: 0) {
            ForEach(Array(grid.rows.enumerated()), id: \.offset) { index, row in
                Text(verbatim: labels[index] ?? "")
                    .font(Typography.tracker(UIMetrics.calendarHourFont, .semibold))
                    .foregroundStyle(Night.faint)
                    .padding(.top, UIMetrics.calendarRailLabelTop)
                    .padding(.trailing, UIMetrics.calendarRailLabelTrailing)
                    .frame(width: UIMetrics.calendarHourLabelWidth, height: CGFloat(row.height), alignment: .topTrailing)
                    .id(index)
            }
        }
    }
}
