import SathiCore
import SwiftUI

struct SettingsSidebar: View {
    @EnvironmentObject var e: Engine
    @Binding var tab: SettingsTab

    var body: some View {
        let engine = e
        VStack(alignment: .leading, spacing: UIMetrics.sidebarSpacing) {
            SidebarLogo()
            SidebarNavButton(title: "General", icon: "slider.horizontal.3", tint: Night.muted, tab: .general, selection: $tab)
            Text(verbatim: "BUDDIES")
                .font(Typography.sectionLabel)
                .tracking(UIMetrics.labelTracking)
                .foregroundStyle(Night.faint)
                .padding(UIMetrics.navPadding)
            ForEach(HabitID.allCases) { id in
                HStack {
                    SidebarNavButton(title: id.name, icon: Self.icon(id), tint: Night.accent(id), tab: .habit(id), selection: $tab) {
                        if Self.isNew(id) { NewBadge() }
                    }
                    BuddySwitch(isOn: engine.enabledBinding(id), accent: Night.accent(id), label: "\(id.name) reminders")
                }
            }
            SidebarNavButton(title: "Add a buddy", icon: "plus.circle", tint: Night.sprout, textColor: Night.sprout, tab: .addBuddy, selection: $tab)
            Spacer()
            OpenReportsRow()
        }
        .padding(UIMetrics.sidebarPadding)
        .padding(.top, UIMetrics.titleBarInset)
    }

    static func icon(_ id: HabitID) -> String {
        switch id {
        case .water: return "drop.fill"
        case .reading: return "book.fill"
        case .meditation: return "leaf.fill"
        }
    }

    static func isNew(_ id: HabitID) -> Bool {
        switch id {
        case .water, .reading: return false
        case .meditation: return true
        }
    }
}

struct SidebarLogo: View {
    var body: some View {
        HStack(spacing: UIMetrics.sectionSpacing) {
            Image(systemName: "leaf.fill")
                .font(.system(size: UIMetrics.logoIconSize, weight: .bold))
                .foregroundStyle(Night.onAccent)
                .frame(width: UIMetrics.logoSize, height: UIMetrics.logoSize)
                .background(Circle().fill(Night.sprout))
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: "Sathi")
                    .font(Typography.rowLabel)
                    .foregroundStyle(Night.text)
                Text(verbatim: "Your little helpers")
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
            }
        }
        .padding(UIMetrics.navPadding)
        .padding(.bottom, UIMetrics.sectionSpacing)
    }
}

struct NewBadge: View {
    var body: some View {
        Text(verbatim: "NEW")
            .font(Typography.badge)
            .foregroundStyle(Night.onAccent)
            .padding(UIMetrics.badgePadding)
            .background(Capsule().fill(Night.calm))
    }
}

struct OpenReportsRow: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        Button { e.openReports() } label: {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .frame(width: UIMetrics.navIconSize)
                Text(verbatim: "Open reports")
                    .font(Typography.rowLabel)
                Spacer()
            }
            .foregroundStyle(Night.text)
            .padding(UIMetrics.navPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
