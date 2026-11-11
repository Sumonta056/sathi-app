import SathiCore
import SwiftUI

struct ReportsPage: View {
    @EnvironmentObject var e: Engine
    @State private var picked: StatsRange?
    @State private var selected: HabitID?

    init(range: StatsRange? = nil, selected: HabitID? = nil) {
        _picked = State(initialValue: range)
        _selected = State(initialValue: selected)
    }

    var body: some View {
        let range = picked ?? e.currentRange(.week)
        let buddy = e.buddyRange(range)
        ScrollView {
            VStack(alignment: .leading, spacing: UIMetrics.reportsPageGap) {
                header(range)
                BuddyTotalsRow(totals: buddy.totals, kind: range.kind, selected: $selected)
                HStack(alignment: .top, spacing: UIMetrics.tileGap) {
                    GoalDaysChart(bars: buddy.bars, kind: range.kind, calendar: e.rangeCalendar, now: e.now)
                    CategoryTimeCard(stats: e.activityRange(range), kind: range.kind, categories: e.activityCategories)
                }
                .frame(height: UIMetrics.reportsCardsHeight)
                if let selected {
                    HabitReportsView(range: range, selected: selected)
                }
            }
            .padding(UIMetrics.mainContentPadding)
            .padding(.top, UIMetrics.titleBarInset)
        }
    }

    private func header(_ range: StatsRange) -> some View {
        HStack(spacing: UIMetrics.reportsGap) {
            Text(verbatim: Copywriter.mainPageReports)
                .font(Typography.tracker(UIMetrics.mainPageTitleFont, .heavy))
                .foregroundStyle(Night.text)
            Spacer(minLength: 0)
            RangeBar(range: rangeBinding(range), now: e.now, calendar: e.rangeCalendar)
            ReportsExportButton(range: range)
        }
    }

    private func rangeBinding(_ range: StatsRange) -> Binding<StatsRange> {
        Binding(get: { range }, set: { picked = $0 })
    }
}
