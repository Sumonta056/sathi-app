import SathiCore
import SwiftUI

struct ReportsPage: View {
    @EnvironmentObject var e: Engine
    @State private var picked: StatsRange?
    @State private var selected: HabitID?
    @State private var memo = RangeMemo<StatsRange, ReportsOverview>()

    init(range: StatsRange? = nil, selected: HabitID? = nil) {
        _picked = State(initialValue: range)
        _selected = State(initialValue: selected)
    }

    var body: some View {
        let range = picked ?? e.currentRange(.week)
        let overview = memo.value(range, range: range, engine: e) { $0.reportsOverview($1) }
        let shown = Self.shown(selected, scores: overview.scores)
        ScrollView {
            VStack(alignment: .leading, spacing: UIMetrics.reportsPageGap) {
                header(range)
                ReportsTabRow(scores: overview.scores, selected: Binding(get: { shown }, set: { selected = $0 }))
                if let shown {
                    ReportsBuddyTab(range: range, habit: shown)
                } else {
                    ReportsAllTab(range: range, overview: overview) { selected = $0 }
                }
            }
            .padding(UIMetrics.mainContentPadding)
            .padding(.top, UIMetrics.titleBarInset)
        }
    }

    static func shown(_ selected: HabitID?, scores: [BuddyScore]) -> HabitID? {
        scores.first { $0.habit == selected && !$0.isOff }?.habit
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
