import SathiCore
import SwiftUI

struct HabitReportsView: View {
    @EnvironmentObject var e: Engine
    let range: StatsRange
    let selected: HabitID
    @State private var memo = RangeMemo<HabitReportRequest, ReportScreen>()

    var body: some View {
        let request = HabitReportRequest(range: range, selected: selected)
        let screen = memo.value(request, range: range, engine: e) { $0.reportScreen($1.range, selected: $1.selected) }
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

struct HabitReportRequest: Equatable {
    let range: StatsRange
    let selected: HabitID
}
