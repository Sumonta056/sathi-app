import SathiCore
import SwiftUI

struct DashboardPage: View {
    let kind: ReportRange
    @State private var picked: StatsRange?
    @State private var selected: HabitID?
    @State private var memo = RangeMemo<StatsRange, ReportsOverview>()
    @State private var dash = DashboardMemo()
    @EnvironmentObject var e: Engine

    init(kind: ReportRange, range: StatsRange? = nil, selected: HabitID? = nil) {
        self.kind = kind
        _picked = State(initialValue: range)
        _selected = State(initialValue: selected)
    }

    var body: some View {
        let range = picked ?? e.currentRange(kind)
        let overview = memo.value(range, range: range, engine: e) { $0.reportsOverview($1) }
        let shown = Self.shown(selected, scores: overview.scores)
        let content = Self.content(range: range, now: e.now, selected: shown)
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: UIMetrics.reportsPageGap) {
                DashboardHeader(range: rangeBinding(range), dateLine: dash.dateLine(engine: e), score: score(content, range, overview))
                ReportsTabRow(scores: overview.scores, selected: Binding(get: { shown }, set: { selected = $0 }))
                page(content, range: range, overview: overview)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(UIMetrics.mainContentPadding)
        }
    }

    static func shown(_ selected: HabitID?, scores: [BuddyScore]) -> HabitID? {
        scores.first { $0.habit == selected && !$0.isOff }?.habit
    }

    @ViewBuilder private func page(_ content: DashboardContent, range: StatsRange, overview: ReportsOverview) -> some View {
        switch content {
        case .today: DashboardTodayContent()
        case .all: ReportsAllTab(range: range, overview: overview) { selected = $0 }
        case let .buddy(habit): ReportsBuddyTab(range: range, habit: habit)
        }
    }

    private func score(_ content: DashboardContent, _ range: StatsRange, _ overview: ReportsOverview) -> DashboardScore? {
        guard content == .today else { return nil }
        return dash.score(range, overview: overview, engine: e)
    }

    private func rangeBinding(_ range: StatsRange) -> Binding<StatsRange> {
        Binding(get: { range }, set: { picked = $0 })
    }
}
