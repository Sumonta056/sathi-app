import SathiCore
import SwiftUI

struct BuddyTabCard: View {
    let tab: BuddyTabReport
    @Environment(\.mainLayout) private var layout

    var body: some View {
        Group {
            if layout.isNarrow {
                VStack(alignment: .leading, spacing: UIMetrics.reportsScoreGap) {
                    chart.frame(height: UIMetrics.reportsBuddyChartNarrowHeight)
                    Rectangle().fill(Night.divider).frame(height: UIMetrics.cardBorder)
                    facts.frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(UIMetrics.reportsBuddyCardPadding)
            } else {
                HStack(alignment: .top, spacing: UIMetrics.reportsScoreGap) {
                    chart
                    Rectangle().fill(Night.divider).frame(width: UIMetrics.cardBorder)
                    facts.frame(width: UIMetrics.reportsFactsWidth, alignment: .leading)
                }
                .padding(UIMetrics.reportsBuddyCardPadding)
                .frame(height: UIMetrics.reportsBuddyCardHeight)
            }
        }
        .background(shape.fill(Night.card))
        .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
    }

    private var chart: some View {
        VStack(alignment: .leading, spacing: UIMetrics.sectionSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: UIMetrics.reportsFactsGap) {
                Text(verbatim: tab.title)
                    .font(Typography.tracker(UIMetrics.reportsBuddyTitleFont, .heavy))
                    .foregroundStyle(Night.text)
                if tab.chart.goal != nil {
                    Text(verbatim: tab.goalText)
                        .font(Typography.tracker(UIMetrics.reportsMonthFont, .semibold))
                        .foregroundStyle(Night.muted)
                }
            }
            ReportChartView(chart: tab.chart, habit: tab.habit)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var facts: some View {
        VStack(alignment: .leading, spacing: UIMetrics.reportsFactsGap) {
            Text(verbatim: tab.totalLabel)
                .font(Typography.tracker(UIMetrics.reportsWeekdayFont, .bold))
                .foregroundStyle(Night.muted)
            Text(verbatim: tab.totalText)
                .font(Typography.tracker(UIMetrics.reportsBuddyTotalFont, .heavy))
                .foregroundStyle(Night.accent(tab.habit))
                .lineLimit(1)
                .minimumScaleFactor(UIMetrics.reportsGridMinScale)
            if !tab.changeText.isEmpty {
                Text(verbatim: tab.changeText)
                    .font(Typography.tracker(UIMetrics.reportsMonthFont, .semibold))
                    .foregroundStyle(tab.isUp ? Night.sprout : Night.muted)
            }
            Rectangle().fill(Night.divider).frame(height: UIMetrics.cardBorder)
            ReportFactsView(facts: tab.facts)
            Spacer(minLength: 0)
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
    }
}
