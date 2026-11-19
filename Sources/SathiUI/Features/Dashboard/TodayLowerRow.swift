import SathiCore
import SwiftUI

struct TodayLowerRow: View {
    let items: [ComingUpItem]
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
            }
            .accessibilityIdentifier(MainLayout.stackedIdentifier)
        } else {
            HStack(alignment: .top, spacing: UIMetrics.dayLowerRowGap) {
                streak(data, month)
                coming
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

    static func streakMonth(_ month: StatsRange, memo: RangeMemo<StatsRange, OverviewMonth>, engine: Engine) -> OverviewMonth {
        streakMonth(month, memo: memo, engine: engine) { $0.streakOverview($1) }
    }

    static func streakMonth(
        _ month: StatsRange, memo: RangeMemo<StatsRange, OverviewMonth>, engine: Engine, build: (Engine, StatsRange) -> OverviewMonth
    ) -> OverviewMonth {
        memo.value(month, end: month.interval.start, engine: engine, build: build)
    }
}
