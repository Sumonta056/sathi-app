import Charts
import SathiCore
import SwiftUI

struct ReportChartView: View {
    let chart: ReportChart
    let habit: HabitID

    var body: some View {
        let color = Night.accent(habit)
        Chart {
            ForEach(chart.bars) { bar in
                BarMark(
                    x: .value("Bucket", String(bar.id)),
                    y: .value("Amount", bar.value),
                    width: .ratio(UIMetrics.chartBarFill)
                )
                .cornerRadius(UIMetrics.chartBarRadius)
                .foregroundStyle(bar.metGoal ? color : color.opacity(UIMetrics.chartDimOpacity))
                .annotation(position: .top) {
                    if bar.value > 0 {
                        Text(verbatim: Self.valueText(bar, habit: habit, hasGoal: chart.goal != nil))
                            .font(Typography.tracker(UIMetrics.reportsBarLabelFont, bar.metGoal ? .heavy : .semibold))
                            .foregroundStyle(bar.metGoal ? Night.text : Night.muted)
                    }
                }
            }
            if let goal = chart.goal {
                RuleMark(y: .value("Goal", goal))
                    .lineStyle(Self.goalStroke)
                    .foregroundStyle(Night.faint)
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    Text(verbatim: label(value.as(String.self)))
                        .font(Typography.badge)
                        .foregroundStyle(Night.faint)
                }
            }
        }
        .chartYAxis(.hidden)
    }

    static let goalStroke = StrokeStyle(lineWidth: UIMetrics.chartGoalLine, dash: UIMetrics.chartGoalDash)

    static func valueText(_ bar: ReportBar, habit: HabitID, hasGoal: Bool) -> String {
        Copywriter.reportsBarValue(habit, bar.value, metGoal: hasGoal && bar.metGoal)
    }

    private func label(_ id: String?) -> String {
        chart.bars.first { String($0.id) == id }?.label ?? ""
    }
}
