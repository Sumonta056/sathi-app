import SathiCore
import SwiftUI

struct ReportsBuddyTab: View {
    @EnvironmentObject var e: Engine
    let range: StatsRange
    let habit: HabitID
    @State private var memo = RangeMemo<BuddyTabRequest, BuddyTabReport>()
    @Environment(\.mainLayout) private var layout

    var body: some View {
        let tab = memo.value(BuddyTabRequest(range: range, habit: habit), range: range, engine: e) {
            $0.buddyTab($1.range, habit: $1.habit)
        }
        VStack(alignment: .leading, spacing: UIMetrics.reportsGap) {
            BuddyTabCard(tab: tab)
            if layout.isNarrow {
                month
            } else {
                HStack(alignment: .top, spacing: UIMetrics.reportsGap) {
                    month
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var month: some View {
        BuddyMonthCard(start: ReportsAllTab.month(range, now: e.now, calendar: e.rangeCalendar), habit: habit)
            .id(BuddyTabRequest(range: range, habit: habit))
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
