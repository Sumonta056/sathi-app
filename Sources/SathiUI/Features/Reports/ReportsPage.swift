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
        ScrollView {
            VStack(alignment: .leading, spacing: UIMetrics.reportsPageGap) {
                header(range)
                ReportsTabRow(scores: overview.scores, selected: $selected)
                if let selected {
                    ReportsBuddyTab(range: range, habit: selected)
                } else {
                    ReportsAllTab(range: range, overview: overview) { selected = $0 }
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
