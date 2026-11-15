import SathiCore
import SwiftUI

struct MainView: View {
    @ObservedObject var route: MainRoute
    @AppStorage(StorageKeys.sidebarOpen) private var sidebarOpen = true
    @State private var sidebarOverlay = false
    @EnvironmentObject var e: Engine

    var body: some View {
        GeometryReader { proxy in
            let layout = MainLayout(width: proxy.size.width)
            HStack(spacing: 0) {
                MainSidebar(route: route, isOpen: $sidebarOpen) { sidebarOverlay = true }
                page
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(Night.bg)
            }
            .overlay(alignment: .leading) {
                if layout.isNarrow { MainSidebarOverlay(route: route, isShown: $sidebarOverlay) }
            }
            .ignoresSafeArea()
            .environment(\.mainLayout, layout)
            .onAppear { route.settle(calendarOn: e.data.prefs.calendarPage.isOn) }
            .onChange(of: e.data.prefs.calendarPage.isOn) { route.settle(calendarOn: $0) }
            .onChange(of: route.page) { _ in route.settle(calendarOn: e.data.prefs.calendarPage.isOn) }
            .onChange(of: layout.isNarrow) { if !$0 { sidebarOverlay = false } }
        }
        .frame(minWidth: UIMetrics.mainLayoutMinSize.width, minHeight: UIMetrics.mainLayoutMinSize.height)
        .ignoresSafeArea()
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
