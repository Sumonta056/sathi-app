import SathiCore
import SwiftUI

struct ReportsAllTab: View {
    @EnvironmentObject var e: Engine
    let range: StatsRange
    let overview: ReportsOverview
    let open: (HabitID) -> Void
    @State private var memo = RangeMemo<StatsRange, ActivityRangeStats>()

    var body: some View {
        let stats = memo.value(range, range: range, engine: e) { $0.activityRange($1) }
        VStack(alignment: .leading, spacing: UIMetrics.reportsGap) {
            ReportsScoreCard(overview: overview)
            DayByDayCard(overview: overview, open: open)
            HStack(alignment: .top, spacing: UIMetrics.reportsGap) {
                ReportsCategoryCard(stats: stats, kind: range.kind, categories: e.activityCategories)
                StreakOverviewCard(start: Self.month(range, now: e.now, calendar: e.rangeCalendar))
                    .id(range.interval)
            }
        }
    }

    static func month(_ range: StatsRange, now: Date, calendar: Calendar) -> StatsRange {
        let last = range.interval.end.addingTimeInterval(-Timing.second)
        return StatsRange.containing(min(now, last), kind: .month, calendar: calendar)
    }
}
