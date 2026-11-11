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
        var cal = Calendar.current
        cal.timeZone = e.timeZone
        return VStack(alignment: .leading, spacing: UIMetrics.todayPageSpacing) {
            TodayHeader(dateLine: screen.dateLine, greeting: screen.greeting)
            TodayNowCard(now: screen.now, calendar: cal)
            TodayBuddyGrid(buddies: screen.buddies, calendar: cal)
            HStack(alignment: .top, spacing: UIMetrics.todayGridGap) {
                TodaySoFarCard(sofar: screen.sofar, categories: e.activityCategories, calendar: cal)
                    .layoutPriority(UIMetrics.todayLowerLeftWeight)
                TodayComingUp(items: screen.comingUp, calendar: cal)
            }
            .frame(maxHeight: .infinity)
        }
    }
}
