import SathiCore
import SwiftUI

struct SidebarRail: View {
    @EnvironmentObject var e: Engine
    @ObservedObject var route: MainRoute
    let toggle: () -> Void

    var body: some View {
        VStack(spacing: UIMetrics.sidebarRailSpacing) {
            logo
            SidebarToggleButton(isOpen: false, size: UIMetrics.sidebarRailToggleSize, toggle: toggle)
                .padding(.bottom, UIMetrics.sidebarRailLogoGap)
            ScrollView(showsIndicators: false) {
                VStack(spacing: UIMetrics.sidebarRailSpacing) {
                    pageButton(Copywriter.mainPageToday, "sun.max", route.page == .today) { route.page = .today }
                    pageButton(Copywriter.mainPageActivities, "list.bullet", isActivities) { route.page = .activities(nil) }
                    pageButton(Copywriter.mainPageReports, "chart.bar", route.page == .reports) { route.page = .reports }
                    Rectangle().fill(Night.border)
                        .frame(width: UIMetrics.sidebarRailDividerWidth, height: UIMetrics.dividerHeight)
                        .padding(.vertical, UIMetrics.sidebarRailDividerGap)
                    ForEach(SettingsPage.all, id: \.self) { settingsTile($0) }
                }
            }
            trackerDot
            githubLink
            Text(verbatim: Copywriter.sidebarVersion(SidebarFooter.version))
                .font(Typography.tracker(UIMetrics.sidebarRailVersionFont, .regular))
                .foregroundStyle(Night.faint)
        }
        .padding(.top, UIMetrics.sidebarRailTopInset)
        .padding(.bottom, UIMetrics.sidebarRailBottomPadding)
        .frame(width: UIMetrics.sidebarRailWidth)
        .frame(maxHeight: .infinity)
        .background(Night.sidebar)
        .overlay(alignment: .trailing) { Rectangle().fill(Night.divider).frame(width: UIMetrics.dividerHeight) }
    }

    private var logo: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: UIMetrics.logoIconSize, weight: .bold))
            .foregroundStyle(Night.onAccent)
            .frame(width: UIMetrics.mainLogoSize, height: UIMetrics.mainLogoSize)
            .background(RoundedRectangle(cornerRadius: UIMetrics.mainLogoRadius, style: .continuous).fill(Night.water))
            .padding(.bottom, UIMetrics.sidebarRailLogoGap)
            .accessibilityHidden(true)
    }

    private func pageButton(_ title: String, _ icon: String, _ on: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: UIMetrics.sidebarRailPageIcon))
                .foregroundStyle(on ? Night.text : Night.muted)
                .frame(width: UIMetrics.sidebarRailPageSize.width, height: UIMetrics.sidebarRailPageSize.height)
                .background(RoundedRectangle(cornerRadius: UIMetrics.mainItemRadius, style: .continuous).fill(on ? Night.navSelected : .clear))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(title)
        .accessibilityLabel(title)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func settingsTile(_ page: SettingsPage) -> some View {
        let on = route.page == .settings(page)
        return Button { route.page = .settings(page) } label: {
            SidebarTile(page: page, size: UIMetrics.sidebarRailTileSize, iconSize: UIMetrics.sidebarRailTileIcon, outlined: on)
                .padding(.vertical, UIMetrics.sidebarRailTileGap)
        }
        .buttonStyle(.plain)
        .help(Copywriter.sidebarSettingsTitle(page))
        .accessibilityLabel(Copywriter.sidebarSettingsTitle(page))
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private var trackerDot: some View {
        let on = e.data.prefs.tracker.isOn
        let hint = on ? Copywriter.sidebarTrackerOnHint : Copywriter.sidebarTrackerOffHint
        return Circle()
            .fill(on ? Night.tracker : Night.faint)
            .frame(width: UIMetrics.sidebarDotSize, height: UIMetrics.sidebarDotSize)
            .padding(UIMetrics.sidebarDotHalo)
            .background(Circle().fill(on ? Night.trackerFill : .clear))
            .frame(width: UIMetrics.sidebarDotHit, height: UIMetrics.sidebarDotHit)
            .contentShape(Rectangle())
            .padding(.bottom, UIMetrics.sidebarDotBottomGap)
            .help(hint)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(hint)
    }

    private var githubLink: some View {
        Link(destination: Links.github) {
            GitHubMark()
                .frame(width: UIMetrics.sidebarLinkIcon, height: UIMetrics.sidebarLinkIcon)
                .foregroundStyle(Night.muted)
                .frame(width: UIMetrics.sidebarRailLinkSize.width, height: UIMetrics.sidebarRailLinkSize.height)
        }
        .help(Copywriter.sidebarGitHub)
        .accessibilityLabel(Copywriter.sidebarGitHub)
    }

    private var isActivities: Bool {
        if case .activities = route.page { return true }
        return false
    }
}
