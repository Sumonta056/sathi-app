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
        case .today: TodayPlaceholder()
        case let .activities(day): ActivitiesPage(day: day)
        case .reports: ReportsPage()
        case let .settings(page): SettingsPageView(page: page)
        }
    }
}

struct TodayPlaceholder: View {
    var body: some View {
        Text(verbatim: Copywriter.mainPageToday)
            .font(Typography.tracker(UIMetrics.mainPageTitleFont, .heavy))
            .foregroundStyle(Night.text)
            .padding(UIMetrics.mainContentPadding)
            .padding(.top, UIMetrics.titleBarInset)
    }
}
