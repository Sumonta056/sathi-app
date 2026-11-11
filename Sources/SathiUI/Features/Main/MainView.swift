import SathiCore
import SwiftUI

struct MainView: View {
    @ObservedObject var route: MainRoute

    var body: some View {
        HStack(spacing: 0) {
            MainSidebar(route: route)
            page
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Night.bg)
        }
        .frame(minWidth: UIMetrics.mainWindowMinSize.width, minHeight: UIMetrics.mainWindowMinSize.height)
        .ignoresSafeArea()
    }

    @ViewBuilder private var page: some View {
        switch route.page {
        case .today: TodayPage()
        case let .activities(day): ActivitiesPage(day: day)
        case .reports: ReportsPage()
        case let .settings(page): SettingsPageView(page: page)
        }
    }
}
