import SathiCore
import SwiftUI

struct MainView: View {
    @EnvironmentObject var e: Engine
    @ObservedObject var route: MainRoute
    @AppStorage(StorageKeys.sidebarOpen) private var sidebarOpen = true

    var body: some View {
        HStack(spacing: 0) {
            MainSidebar(route: route, isOpen: $sidebarOpen)
            page
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Night.bg)
        }
        .frame(minWidth: UIMetrics.mainWindowMinSize.width, minHeight: UIMetrics.mainWindowMinSize.height)
        .ignoresSafeArea()
        .onAppear { route.settle(calendarOn: e.data.prefs.calendarPage.isOn) }
        .onChange(of: e.data.prefs.calendarPage.isOn) { route.settle(calendarOn: $0) }
        .onChange(of: route.page) { _ in route.settle(calendarOn: e.data.prefs.calendarPage.isOn) }
    }

    @ViewBuilder private func calendarPage(_ day: DayKey?) -> some View {
        if e.data.prefs.calendarPage.isOn { CalendarPage(day: day) } else { TodayPage() }
    }

    @ViewBuilder private var page: some View {
        switch route.page {
        case .today: TodayPage()
        case let .activities(day): ActivitiesPage(day: day)
        case let .calendar(day): calendarPage(day)
        case .reports: ReportsPage()
        case let .settings(page): SettingsPageView(page: page)
        }
    }
}
