import SathiCore
import SwiftUI

struct DashboardHeader: View {
    @EnvironmentObject var e: Engine
    @Binding var range: StatsRange
    let score: DashboardScore?

    private var holdsToday: Bool {
        range.kind == .day && range.holds(e.now)
    }

    var body: some View {
        PageHeaderLayout(gap: UIMetrics.reportsGap) {
            titles
            controls.fixedSize()
        }
    }

    private var titles: some View {
        VStack(alignment: .leading, spacing: UIMetrics.todayHeaderGap) {
            Text(verbatim: e.dashboardDateLine)
                .font(Typography.tracker(UIMetrics.todayDateFont, .semibold))
                .tracking(UIMetrics.todayDateTracking)
                .foregroundStyle(Night.label)
            Text(verbatim: holdsToday ? e.greeting : Copywriter.mainPageDashboard)
                .font(Typography.tracker(UIMetrics.todayTitleFont, .heavy))
                .foregroundStyle(Night.text)
                .lineLimit(1)
            if let score {
                DashboardScoreLine(score: score)
            }
        }
        .fixedSize()
    }

    private var controls: some View {
        HStack(spacing: UIMetrics.todayButtonGap) {
            RangeBar(range: $range, now: e.now, calendar: e.rangeCalendar)
            Rectangle()
                .fill(Night.border)
                .frame(width: UIMetrics.dashboardDividerWidth, height: UIMetrics.dashboardDividerHeight)
            if holdsToday {
                Button { e.openQuickAdd() } label: { Text(verbatim: Copywriter.todayQuickReminder) }
                    .buttonStyle(TodayHeaderButton())
                BreakMenu()
            } else {
                ReportsExportButton(range: range)
            }
        }
    }
}
