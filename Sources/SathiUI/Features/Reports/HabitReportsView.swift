import SathiCore
import SwiftUI

struct HabitReportsView: View {
    @EnvironmentObject var e: Engine
    let range: StatsRange
    let selected: HabitID

    var body: some View {
        let screen = e.reportScreen(range, selected: selected)
        HStack(alignment: .top, spacing: UIMetrics.tileGap) {
            ReportsCard {
                Text(verbatim: screen.chart.title)
                    .font(Typography.rowLabel)
                    .foregroundStyle(Night.text)
                ReportChartView(chart: screen.chart, habit: screen.selected)
            }
            ReportsCard {
                StreakCalendarView(month: screen.calendar)
                Spacer(minLength: 0)
                ReportFactsView(facts: screen.facts)
            }
            .frame(width: UIMetrics.calendarWidth)
        }
        .frame(height: UIMetrics.reportsDetailHeight)
    }
}
