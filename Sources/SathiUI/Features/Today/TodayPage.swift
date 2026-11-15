import SathiCore
import SwiftUI

struct TodayPage: View {
    @StateObject private var model = TodayModel()
    @Environment(\.mainLayout) private var layout
    @EnvironmentObject var e: Engine

    var body: some View {
        page(model.screen ?? e.todayScreen)
            .onAppear { model.attach(e) }
            .onDisappear { model.detach() }
    }

    @ViewBuilder private func page(_ screen: TodayScreen) -> some View {
        if layout.isNarrow {
            ScrollView(.vertical, showsIndicators: false) {
                content(screen)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(UIMetrics.mainContentPadding)
            }
        } else {
            content(screen)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(UIMetrics.mainContentPadding)
        }
    }

    private func content(_ screen: TodayScreen) -> some View {
        let cal = e.rangeCalendar
        return VStack(alignment: .leading, spacing: UIMetrics.todayPageSpacing) {
            TodayHeader(e: e, dateLine: screen.dateLine, greeting: screen.greeting)
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
            .frame(maxHeight: .infinity)
        }
    }
}
