import SathiCore
import SwiftUI

struct GymSettingsTab: View {
    private static let copy = HeroCopy(
        eyebrow: "SHOKTI · GYM",
        title: "Get up, little and often",
        hint: "Shokti suggests a short workout between your work.",
        switchLabel: "Gym reminders"
    )

    var body: some View {
        HabitSettingsPage(habit: .gym, copy: Self.copy) {
            EmptyView()
        }
    }
}
