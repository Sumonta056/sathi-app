import Charts
import SathiCore
import SwiftUI

struct GoalDaysChart: View {
    let bars: [GoalDayBar]
    let kind: ReportRange
    let calendar: Calendar
    let now: Date

    var body: some View {
        ReportsCard {
            Text(verbatim: Copywriter.reportsGoalDays(buddies: buddies))
                .font(Typography.rowLabel)
                .foregroundStyle(Night.text)
            Chart {
                ForEach(bars, id: \.day) { bar in
                    BarMark(x: .value("Day", label(bar)), y: .value("Met", bar.isFuture ? 0 : bar.met), width: .ratio(UIMetrics.chartBarFill))
                        .foregroundStyle(Night.sprout)
                    BarMark(
                        x: .value("Day", label(bar)),
                        y: .value("Open", bar.isFuture ? 0 : bar.of - bar.met),
                        width: .ratio(UIMetrics.chartBarFill)
                    )
                    .cornerRadius(UIMetrics.chartBarRadius)
                    .foregroundStyle(Night.switchOff)
                }
            }
            .chartYScale(domain: 0 ... max(buddies, 1))
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        Text(verbatim: value.as(String.self) ?? "")
                            .font(Typography.badge)
                            .foregroundStyle(Night.faint)
                    }
                }
            }
        }
    }

    private var buddies: Int {
        let today = bars.first { calendar.isDate($0.day, inSameDayAs: now) }
        return today?.of ?? bars.map(\.of).max() ?? 0
    }

    private func label(_ bar: GoalDayBar) -> String {
        Copywriter.reportsBarLabel(bar.day, kind: kind, calendar: calendar)
    }
}
