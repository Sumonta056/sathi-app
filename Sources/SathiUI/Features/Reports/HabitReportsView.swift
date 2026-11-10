import SathiCore
import SwiftUI

struct HabitReportsView: View {
    @EnvironmentObject var e: Engine
    @Binding var range: ReportRange
    @Binding var selected: HabitID

    var body: some View {
        let screen = e.reportScreen(range, selected: selected)
        VStack(alignment: .leading, spacing: UIMetrics.reportsGap) {
            ReportsHeader(screen: screen, range: $range)
            HStack(spacing: UIMetrics.tileGap) {
                ForEach(screen.tiles) { tile in
                    HabitTileView(tile: tile, selected: selection(screen))
                }
            }
            HStack(alignment: .top, spacing: UIMetrics.reportsGap) {
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
        }
    }

    private func selection(_ screen: ReportScreen) -> Binding<HabitID> {
        Binding(get: { screen.selected }, set: { selected = $0 })
    }
}
