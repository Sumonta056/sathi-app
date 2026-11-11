import SathiCore
import SwiftUI

struct WaterSettingsTab: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        HabitSettingsPage(habit: .water) {
            SettingsSection("Rhythm") { WaterRhythmCard() }
            DaysOffCard(habit: .water)
            SettingsSection("Daily goal") {
                SettingsCard { GlassGoalRow(goal: $e.data.prefs.water.dailyGoalGlasses) }
            }
            SettingsSection("If I ignore Fota") {
                StrictnessCards(
                    options: Strictness.allCases,
                    selected: engine.data.prefs.water.strictness,
                    accent: Night.water
                ) { engine.data.prefs.water.strictness = $0 }
                CloseButtonCard(habit: .water)
            }
        }
    }
}
