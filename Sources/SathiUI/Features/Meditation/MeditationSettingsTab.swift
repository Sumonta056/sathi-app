import SathiCore
import SwiftUI

struct MeditationSettingsTab: View {
    private static let copy = HeroCopy(
        eyebrow: "SHANTI · MEDITATION",
        title: "Pause. Breathe. Come back.",
        hint: "Shanti guides a short breath with a soft glowing circle.",
        switchLabel: "Meditation reminders"
    )

    var body: some View {
        HabitSettingsPage(habit: .meditation, copy: Self.copy) {
            SettingsSection("When") { MeditationWhenCard() }
            SettingsSection("Breathing pattern") { BreathingPatternCards() }
        }
    }
}
