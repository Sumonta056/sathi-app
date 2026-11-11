import SathiCore
import SwiftUI

struct MeditationSettingsTab: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        HabitSettingsPage(habit: .meditation) {
            SettingsSection("Goal") { MeditationGoalCard() }
            SettingsSection("Rhythm") { MeditationRhythmCard() }
            DaysOffCard(habit: .meditation)
            SettingsSection("Breathing pattern") { BreathingPatternCards() }
            SoundLink()
            SettingsSection("If I ignore Shanti") {
                StrictnessCards(
                    options: Strictness.allCases,
                    selected: engine.data.prefs.meditation.strictness,
                    accent: Night.calm
                ) { engine.data.prefs.meditation.strictness = $0 }
                CloseButtonCard(habit: .meditation)
            }
        }
    }
}
