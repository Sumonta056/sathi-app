import SathiCore
import SwiftUI

struct ReportsBuddyTab: View {
    @EnvironmentObject var e: Engine
    let range: StatsRange
    let habit: HabitID
    @State private var memo = RangeMemo<BuddyTabRequest, BuddyTabReport>()

    var body: some View {
        let tab = memo.value(BuddyTabRequest(range: range, habit: habit), range: range, engine: e) {
            $0.buddyTab($1.range, habit: $1.habit)
        }
        VStack(alignment: .leading, spacing: UIMetrics.reportsGap) {
            BuddyTabCard(tab: tab)
            HStack(alignment: .top, spacing: UIMetrics.reportsGap) {
                BuddyMonthCard(start: ReportsAllTab.month(range, now: e.now, calendar: e.rangeCalendar), habit: habit)
                    .id(BuddyTabRequest(range: range, habit: habit))
                Spacer(minLength: 0)
            }
        }
    }
}

struct BuddyTabRequest: Equatable, Hashable {
    let range: StatsRange
    let habit: HabitID

    func hash(into hasher: inout Hasher) {
        hasher.combine(range.interval)
        hasher.combine(habit)
    }
}

struct BuddyTabCard: View {
    let tab: BuddyTabReport

    var body: some View {
        let accent = Night.accent(tab.habit)
        HStack(alignment: .top, spacing: UIMetrics.reportsScoreGap) {
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
            Rectangle().fill(Night.divider).frame(width: UIMetrics.cardBorder)
            VStack(alignment: .leading, spacing: UIMetrics.reportsFactsGap) {
                Text(verbatim: tab.totalLabel)
                    .font(Typography.tracker(UIMetrics.reportsWeekdayFont, .bold))
                    .foregroundStyle(Night.muted)
                Text(verbatim: tab.totalText)
                    .font(Typography.tracker(UIMetrics.reportsBuddyTotalFont, .heavy))
                    .foregroundStyle(accent)
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
            .frame(width: UIMetrics.reportsFactsWidth, alignment: .leading)
        }
        .padding(UIMetrics.reportsBuddyCardPadding)
        .frame(height: UIMetrics.reportsBuddyCardHeight)
        .background(shape.fill(Night.card))
        .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
    }
}
