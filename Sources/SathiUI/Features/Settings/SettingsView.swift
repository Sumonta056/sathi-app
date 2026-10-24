import SathiCore
import SwiftUI

struct SettingsView: View {
    @State private var tab: SettingsTab

    init(tab: SettingsTab = .general) {
        _tab = State(initialValue: tab)
    }

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(tab: $tab)
                .frame(width: UIMetrics.sidebarWidth)
                .frame(maxHeight: .infinity)
                .background(Night.sidebar)
            ScrollView {
                content
                    .padding(UIMetrics.contentPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Night.bg)
        }
        .frame(width: UIMetrics.settingsSize.width, height: UIMetrics.settingsSize.height)
        .ignoresSafeArea()
    }

    @ViewBuilder private var content: some View {
        switch tab {
        case .general: GeneralTab()
        case let .habit(id): HabitTab(id: id)
        case .addBuddy: AddBuddyTab()
        }
    }
}

struct HabitTab: View {
    let id: HabitID

    var body: some View {
        switch id {
        case .water: WaterSettingsTab()
        case .reading: ReadingSettingsTab()
        case .meditation: MeditationSettingsTab()
        }
    }
}
