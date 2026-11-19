import SathiCore
import SwiftUI

struct TodayLowerRow: View {
    let items: [ComingUpItem]
    let sofar: TodaySoFar
    let categories: [ActivityCategory]
    let calendar: Calendar
    let now: Date
    @Environment(\.mainLayout) private var layout
    @State private var picked: StatsRange?
    @State private var memo = RangeMemo<StatsRange, OverviewMonth>()
    @EnvironmentObject var e: Engine

    var body: some View {
        let month = picked ?? StatsRange.containing(now, kind: .month, calendar: e.rangeCalendar)
        let data = Self.streakMonth(month, memo: memo, engine: e)
        if layout.isNarrow {
            VStack(alignment: .leading, spacing: UIMetrics.dayLowerRowGap) {
                streak(data, month)
                coming
                breakdown
            }
            .accessibilityIdentifier(MainLayout.stackedIdentifier)
        } else {
            HStack(alignment: .top, spacing: UIMetrics.dayLowerRowGap) {
                streak(data, month)
                coming
                breakdown.frame(width: UIMetrics.dayBreakdownCardWidth)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func streak(_ data: OverviewMonth, _ month: StatsRange) -> some View {
        StreakOverviewView(month: data) { step in
            picked = step < 0 ? month.previous : month.next
        }
    }

    private var coming: some View {
        TodayComingUp(items: items, calendar: calendar, now: now)
    }

    @ViewBuilder private var breakdown: some View {
        if Self.showsBreakdown(sofar) {
            DayBreakdownCard(sofar: sofar, categories: categories)
        }
    }

    static func showsBreakdown(_ sofar: TodaySoFar) -> Bool {
        sofar.isOn && !(sofar.categories.isEmpty && sofar.away.isEmpty)
    }

    static func streakMonth(_ month: StatsRange, memo: RangeMemo<StatsRange, OverviewMonth>, engine: Engine) -> OverviewMonth {
        streakMonth(month, memo: memo, engine: engine) { $0.streakOverview($1) }
    }

    static func streakMonth(
        _ month: StatsRange, memo: RangeMemo<StatsRange, OverviewMonth>, engine: Engine, build: (Engine, StatsRange) -> OverviewMonth
    ) -> OverviewMonth {
        perDay(month, memo: memo, engine: engine, build: build)
    }

    private static func perDay(
        _ month: StatsRange, memo: RangeMemo<StatsRange, OverviewMonth>, engine: Engine, build: (Engine, StatsRange) -> OverviewMonth
    ) -> OverviewMonth {
        let pastEnd = month.interval.start
        return memo.value(month, end: pastEnd, engine: engine, build: build)
    }
}
