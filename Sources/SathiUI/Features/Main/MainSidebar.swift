import SathiCore
import SwiftUI

struct MainSidebar: View {
    @ObservedObject var route: MainRoute
    @Binding var isOpen: Bool

    var body: some View {
        Group {
            if isOpen {
                openList
            } else {
                SidebarRail(route: route) { isOpen = true }
            }
        }
        .animation(.easeInOut(duration: UIMetrics.sidebarAnimation), value: isOpen)
    }

    private var openList: some View {
        VStack(alignment: .leading, spacing: UIMetrics.mainSidebarSpacing) {
            MainLogo { isOpen = false }
            MainSidebarItem(title: Copywriter.mainPageToday, icon: "sun.max", isSelected: route.page == .today) {
                route.page = .today
            }
            MainSidebarItem(title: Copywriter.mainPageActivities, icon: "list.bullet", isSelected: isActivities) {
                route.page = .activities(nil)
            }
            MainSidebarItem(title: Copywriter.mainPageReports, icon: "chart.bar", isSelected: route.page == .reports) {
                route.page = .reports
            }
            Text(verbatim: Copywriter.sidebarSettingsHeading)
                .font(Typography.tracker(UIMetrics.sidebarHeadingFont, .heavy))
                .tracking(UIMetrics.sidebarHeadingTracking)
                .foregroundStyle(Night.faint)
                .padding(UIMetrics.sidebarHeadingPadding)
            ForEach(SettingsPage.all, id: \.self) { page in
                SidebarSettingsRow(page: page, isSelected: settingsPage == page) { route.page = .settings(page) }
            }
            Spacer(minLength: 0)
            TrackerStatusBlock()
            SidebarFooter().padding(.top, UIMetrics.sidebarFooterTopGap)
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
    let close: () -> Void

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
            Spacer(minLength: 0)
            SidebarToggleButton(isOpen: true, size: CGSize(width: UIMetrics.sidebarToggleSize, height: UIMetrics.sidebarToggleSize), toggle: close)
        }
        .padding(UIMetrics.sidebarLogoPadding)
    }
}
