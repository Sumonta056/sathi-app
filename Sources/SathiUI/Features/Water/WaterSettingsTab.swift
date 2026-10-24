import SathiCore
import SwiftUI

struct WaterSettingsTab: View {
    @EnvironmentObject var e: Engine

    private static let copy = HeroCopy(
        eyebrow: "FOTA · WATER",
        title: "Small sips, all day long",
        hint: "Fota taps you on the shoulder when it is time for a glass.",
        switchLabel: "Water reminders"
    )

    var body: some View {
        let engine = e
        HabitSettingsPage(habit: .water, copy: Self.copy) {
            SettingsSection("Rhythm") { WaterRhythmCard() }
            SettingsSection("Daily goal") {
                SettingsCard { GlassGoalRow(goal: $e.data.prefs.water.dailyGoalGlasses) }
            }
            SettingsSection("If I ignore Fota") {
                StrictnessCards(
                    options: Strictness.allCases,
                    selected: engine.data.prefs.water.strictness,
                    accent: Night.water
                ) { engine.data.prefs.water.strictness = $0 }
            }
        }
    }
}
