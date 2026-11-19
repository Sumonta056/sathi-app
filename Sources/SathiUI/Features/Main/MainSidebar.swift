import SathiCore
import SwiftUI

struct MainSidebar: View {
    @ObservedObject var route: MainRoute
    @Binding var isOpen: Bool
    var openOverlay: () -> Void = {}
    @Environment(\.mainLayout) private var layout

    var body: some View {
        Group {
            if layout.isNarrow {
                SidebarRail(route: route, toggle: openOverlay)
            } else if isOpen {
                MainSidebarList(route: route) { isOpen = false }
            } else {
                SidebarRail(route: route) { isOpen = true }
            }
        }
        .animation(.easeInOut(duration: UIMetrics.sidebarAnimation), value: isOpen)
    }
}

struct MainSidebarOverlay: View {
    @ObservedObject var route: MainRoute
    @Binding var isShown: Bool
    @Environment(\.mainLayout) private var layout

    var body: some View {
        ZStack(alignment: .leading) {
            if isShown, layout.isNarrow {
                MainDim { isShown = false }
                MainSidebarList(route: route) { isShown = false }
            }
        }
        .onChange(of: route.page) { _ in isShown = false }
        .onChange(of: layout.isNarrow) { if !$0 { isShown = false } }
    }
}

struct MainSidebarList: View {
    @EnvironmentObject var e: Engine
    @ObservedObject var route: MainRoute
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.mainSidebarSpacing) {
            MainLogo(close: close)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: UIMetrics.mainSidebarSpacing) {
                    MainSidebarItem(title: Copywriter.mainPageToday, icon: "sun.max", isSelected: route.page == .dashboard(.day)) {
                        route.page = .dashboard(.day)
                    }
                    if e.data.prefs.todos.isOn {
                        MainSidebarItem(title: Copywriter.mainPageTodos, icon: "checkmark.circle", isSelected: route.page == .todos) {
                            route.page = .todos
                        }
                    }
                    MainSidebarItem(title: Copywriter.mainPageActivities, icon: "list.bullet", isSelected: isActivities) {
                        route.page = .activities(nil)
                    }
                    if e.data.prefs.calendarPage.isOn {
                        MainSidebarItem(title: Copywriter.calendarPageTitle, icon: "calendar", isSelected: isCalendar) {
                            route.page = .calendar(nil)
                        }
                    }
                    MainSidebarItem(title: Copywriter.mainPageReports, icon: "chart.bar", isSelected: route.page == .dashboard(.week)) {
                        route.page = .dashboard(.week)
                    }
                    Text(verbatim: Copywriter.sidebarSettingsHeading)
                        .font(Typography.tracker(UIMetrics.sidebarHeadingFont, .heavy))
                        .tracking(UIMetrics.sidebarHeadingTracking)
                        .foregroundStyle(Night.faint)
                        .padding(UIMetrics.sidebarHeadingPadding)
                    ForEach(SettingsPage.all, id: \.self) { page in
                        SidebarSettingsRow(page: page, isSelected: settingsPage == page) { route.page = .settings(page) }
                    }
                }
            }
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

    private var isCalendar: Bool {
        if case .calendar = route.page { return true }
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
