import SathiCore
import SwiftUI

struct MeditationSettingsTab: View {
    private static let copy = HeroCopy(
        eyebrow: "SHANTI · MEDITATION",
        title: "Pause. Breathe. Come back.",
        hint: "Shanti guides a short breath with a soft glowing circle.",
        switchLabel: "Meditation reminders"
    )

    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        HabitSettingsPage(habit: .meditation, copy: Self.copy) {
            SettingsSection("Goal") { MeditationGoalCard() }
            SettingsSection("Rhythm") { MeditationRhythmCard() }
            SettingsSection("Breathing pattern") { BreathingPatternCards() }
            SettingsSection("If I ignore Shanti") {
                StrictnessCards(
                    options: Strictness.allCases,
                    selected: engine.data.prefs.meditation.strictness,
                    accent: Night.calm
                ) { engine.data.prefs.meditation.strictness = $0 }
            }
        }
    }
}
