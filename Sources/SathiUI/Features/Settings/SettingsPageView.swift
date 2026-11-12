import SathiCore
import SwiftUI

struct SettingsPageView: View {
    let page: SettingsPage

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: UIMetrics.pageSpacing) {
                SettingsHeader(page: page)
                content
                Text(verbatim: Copywriter.settingsSaveNote)
                    .font(Typography.hint)
                    .foregroundStyle(Night.faint)
            }
            .padding(UIMetrics.mainContentPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder private var content: some View {
        switch page {
        case .general: GeneralTab()
        case let .habit(id): HabitTab(id: id)
        case .quickReminders: QuickRemindersPage()
        case .tracker: TrackerSettingsPage()
        case .timeBlocks: TimeBlockSettingsPage()
        case .sound: SoundPage()
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
        case .gym: GymSettingsTab()
        }
    }
}
