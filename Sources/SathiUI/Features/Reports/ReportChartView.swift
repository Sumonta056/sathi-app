import Charts
import SathiCore
import SwiftUI

struct ReportChartView: View {
    let chart: ReportChart
    let habit: HabitID

    var body: some View {
        let color = Night.accent(habit)
        VStack(alignment: .leading, spacing: UIMetrics.sectionSpacing) {
            if chart.goal != nil { legend }
            Chart {
                ForEach(chart.bars) { bar in
                    BarMark(
                        x: .value("Bucket", String(bar.id)),
                        y: .value("Amount", bar.value),
                        width: .ratio(UIMetrics.chartBarFill)
                    )
                    .cornerRadius(UIMetrics.chartBarRadius)
                    .foregroundStyle(bar.metGoal ? color : color.opacity(UIMetrics.chartDimOpacity))
                }
                if let goal = chart.goal {
                    RuleMark(y: .value("Goal", goal))
                        .lineStyle(goalStroke)
                        .foregroundStyle(Night.muted)
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
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(Night.divider)
                    AxisValueLabel().foregroundStyle(Night.faint)
                }
            }
        }
    }

    private var legend: some View {
        HStack(spacing: UIMetrics.dotSpacing) {
            Path { p in
                p.move(to: .zero)
                p.addLine(to: CGPoint(x: UIMetrics.chartLegendWidth, y: 0))
            }
            .stroke(Night.muted, style: goalStroke)
            .frame(width: UIMetrics.chartLegendWidth, height: UIMetrics.chartGoalLine)
            Text(verbatim: "Daily goal")
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
        }
    }

    private var goalStroke: StrokeStyle {
        StrokeStyle(lineWidth: UIMetrics.chartGoalLine, dash: UIMetrics.chartGoalDash)
    }

    private func label(_ id: String?) -> String {
        chart.bars.first { String($0.id) == id }?.label ?? ""
    }
}
