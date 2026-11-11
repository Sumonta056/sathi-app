import SathiCore
import SwiftUI

struct MainSidebar: View {
    @ObservedObject var route: MainRoute

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.mainSidebarSpacing) {
            MainLogo()
            MainSidebarItem(title: Copywriter.mainPageToday, icon: "sun.max", isSelected: route.page == .today) {
                route.page = .today
            }
            MainSidebarItem(title: Copywriter.mainPageActivities, icon: "list.bullet", isSelected: isActivities) {
                route.page = .activities(nil)
            }
            MainSidebarItem(title: Copywriter.mainPageReports, icon: "chart.bar", isSelected: route.page == .reports) {
                route.page = .reports
            }
            MainSidebarItem(title: Copywriter.mainPageSettings, icon: "gearshape", isSelected: settingsPage != nil) {
                if settingsPage == nil { route.page = .settings(.general) }
            }
            if let settingsPage {
                SettingsSubnav(selected: settingsPage) { route.page = .settings($0) }
            }
            Spacer(minLength: 0)
            TrackerStatusBlock()
        }
        .padding(UIMetrics.mainSidebarPadding)
        .padding(.top, UIMetrics.mainTitleBarInset)
        .frame(width: UIMetrics.mainSidebarWidth)
        .frame(maxHeight: .infinity)
        .background(Night.sidebar)
        .overlay(alignment: .trailing) {
            Rectangle().fill(Night.divider).frame(width: UIMetrics.dividerHeight)
        }
    }

    private var isActivities: Bool {
        if case .activities = route.page { return true }
        return false
    }

    private var settingsPage: SettingsPage? {
        if case let .settings(page) = route.page { return page }
        return nil
    }
}

struct MainLogo: View {
    var body: some View {
        HStack(spacing: UIMetrics.mainLogoGap) {
            Image(systemName: "leaf.fill")
                .font(.system(size: UIMetrics.logoIconSize, weight: .bold))
                .foregroundStyle(Night.onAccent)
                .frame(width: UIMetrics.mainLogoSize, height: UIMetrics.mainLogoSize)
                .background(RoundedRectangle(cornerRadius: UIMetrics.mainLogoRadius, style: .continuous).fill(Night.water))
            Text(verbatim: Copywriter.mainAppName)
                .font(Typography.tracker(UIMetrics.mainLogoFont, .heavy))
                .foregroundStyle(Night.text)
        }
        .padding(UIMetrics.mainLogoPadding)
    }
}
