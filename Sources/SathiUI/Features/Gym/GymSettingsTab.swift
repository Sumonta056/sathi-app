import SathiCore
import SwiftUI

struct GymSettingsTab: View {
    private static let copy = HeroCopy(
        eyebrow: "SHOKTI · GYM",
        title: "Get up, little and often",
        hint: "Shokti suggests a short move while you work.",
        switchLabel: "Gym reminders"
    )

    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        HabitSettingsPage(habit: .gym, copy: Self.copy) {
            SettingsSection("Rhythm") { GymRhythmCard() }
            SettingsSection("My 4 workouts") { GymWorkoutsCard() }
            SettingsSection("If I ignore Shokti") {
                StrictnessCards(
                    options: [.friendly, .persistent],
                    selected: engine.data.prefs.strictness(.gym),
                    accent: Night.gym
                ) { engine.data.prefs.gym.strictness = $0 }
            }
        }
    }
}
