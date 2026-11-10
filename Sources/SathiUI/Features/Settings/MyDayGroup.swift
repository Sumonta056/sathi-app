import SathiCore
import SwiftUI

struct MyDayGroup: View {
    @EnvironmentObject var e: Engine
    @Binding var tab: SettingsTab

    var body: some View {
        Text(verbatim: Copywriter.trackerSidebarGroup)
            .font(Typography.sectionLabel)
            .tracking(UIMetrics.labelTracking)
            .foregroundStyle(Night.faint)
            .padding(UIMetrics.navPadding)
        HStack {
            SidebarNavButton(title: Copywriter.trackerSettingsTitle, icon: "pencil.line", tint: Night.tracker, tab: .tracker, selection: $tab)
            BuddySwitch(isOn: e.trackerOn, accent: Night.tracker, label: Copywriter.trackerOnLabel)
        }
    }
}
