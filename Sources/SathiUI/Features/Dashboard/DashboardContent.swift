import Foundation
import SathiCore
import SwiftUI

enum DashboardContent: Equatable {
    case today
    case all
    case buddy(HabitID)
}

extension DashboardPage {
    static func content(range: StatsRange, now: Date, selected: HabitID?) -> DashboardContent {
        if let selected { return .buddy(selected) }
        return range.kind == .day && range.holds(now) ? .today : .all
    }
}

struct DashboardTodayContent: View {
    @StateObject private var model = TodayModel()
    @Environment(\.mainLayout) private var layout
    @EnvironmentObject var e: Engine

    var body: some View {
        content(model.screen ?? e.todayScreen)
            .onAppear { model.attach(e) }
            .onDisappear { model.detach() }
    }

    private func content(_ screen: TodayScreen) -> some View {
        let cal = e.rangeCalendar
        return VStack(alignment: .leading, spacing: UIMetrics.todayPageSpacing) {
            TodayNowCard(e: e, now: screen.now, calendar: cal)
            TodayBuddyGrid(e: e, buddies: screen.buddies, calendar: cal)
            TodaySoFarCard(sofar: screen.sofar, categories: e.activityCategories, calendar: cal, now: screen.at)
            lower(screen, cal)
        }
    }

    @ViewBuilder private func lower(_ screen: TodayScreen, _ cal: Calendar) -> some View {
        if layout.isNarrow {
            VStack(alignment: .leading, spacing: UIMetrics.todayGridGap) {
                TodayBreakdownCard(sofar: screen.sofar, categories: e.activityCategories)
                TodayComingUp(items: screen.comingUp, calendar: cal, now: screen.at)
            }
        } else {
            WeightedRow(gap: UIMetrics.todayGridGap, weights: UIMetrics.todayLowerWeights) {
                TodayBreakdownCard(sofar: screen.sofar, categories: e.activityCategories)
                TodayComingUp(items: screen.comingUp, calendar: cal, now: screen.at)
            }
        }
    }
}
