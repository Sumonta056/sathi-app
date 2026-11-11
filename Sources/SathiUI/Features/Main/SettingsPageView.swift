import SathiCore
import SwiftUI

struct SettingsPageView: View {
    let page: SettingsPage

    var body: some View {
        ScrollView {
            content
                .padding(UIMetrics.mainContentPadding)
                .padding(.top, UIMetrics.titleBarInset)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder private var content: some View {
        switch page {
        case .general: GeneralTab()
        case let .habit(id): HabitTab(id: id)
        case .quickReminders: QuickSettingsCard()
        case .tracker: TrackerSettingsPage()
        case .timeBlocks: TimeBlockSettingsPage()
        case .sound: MeditationSoundCard()
        }
    }
}
