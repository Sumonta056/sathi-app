import SathiCore
import SwiftUI

struct TodayPage: View {
    @EnvironmentObject var e: Engine
    @StateObject private var model = TodayModel()

    var body: some View {
        content(model.screen ?? e.todayScreen)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(UIMetrics.mainContentPadding)
            .padding(.top, UIMetrics.titleBarInset)
            .onAppear { model.attach(e) }
            .onDisappear { model.detach() }
    }

    private func content(_ screen: TodayScreen) -> some View {
        let cal = e.rangeCalendar
        return VStack(alignment: .leading, spacing: UIMetrics.todayPageSpacing) {
            TodayHeader(e: e, dateLine: screen.dateLine, greeting: screen.greeting)
            TodayNowCard(e: e, now: screen.now, calendar: cal)
            TodayBuddyGrid(e: e, buddies: screen.buddies, calendar: cal)
            TodaySoFarCard(sofar: screen.sofar, categories: e.activityCategories, calendar: cal, now: screen.at)
            WeightedRow(gap: UIMetrics.todayGridGap, weights: UIMetrics.todayLowerWeights) {
                TodayBreakdownCard(sofar: screen.sofar, categories: e.activityCategories)
                TodayComingUp(items: screen.comingUp, calendar: cal, now: screen.at)
            }
            .frame(maxHeight: .infinity)
        }
    }
}
