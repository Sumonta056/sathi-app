import SathiCore
import SwiftUI

struct TodayDayContent: View {
    @StateObject private var model = TodayModel()
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
            TodayLowerRow(items: screen.comingUp, sofar: screen.sofar, categories: e.activityCategories, calendar: cal, now: screen.at)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
