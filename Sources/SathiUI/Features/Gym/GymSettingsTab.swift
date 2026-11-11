import SathiCore
import SwiftUI

struct GymSettingsTab: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        HabitSettingsPage(habit: .gym) {
            SettingsSection("Daily goal") { GymGoalCard() }
            SettingsSection("Rhythm") { GymRhythmCard() }
            DaysOffCard(habit: .gym)
            SettingsSection("My workout ideas") { GymIdeasCard() }
            SettingsSection("If I ignore Shokti") {
                StrictnessCards(
                    options: Strictness.allCases,
                    selected: engine.data.prefs.strictness(.gym),
                    accent: Night.gym
                ) { engine.data.prefs.gym.strictness = $0 }
                CloseButtonCard(habit: .gym)
            }
        }
    }
}
