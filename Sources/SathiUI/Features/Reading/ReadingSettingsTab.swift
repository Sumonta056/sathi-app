import SathiCore
import SwiftUI

struct ReadingSettingsTab: View {
    @EnvironmentObject var e: Engine

    private static let copy = HeroCopy(
        eyebrow: "BOI · READING",
        title: "A few pages before bed",
        hint: "Boi peeks in from the corner. It never blocks your screen.",
        switchLabel: "Reading reminders"
    )

    var body: some View {
        let engine = e
        HabitSettingsPage(habit: .reading, copy: Self.copy) {
            SettingsSection("When") { ReadingWhenCard() }
            SettingsSection("How Boi says hi") { ReadingStyleCards() }
            SettingsSection("If I ignore Boi") {
                StrictnessCards(
                    options: [.friendly, .persistent],
                    selected: engine.data.prefs.strictness(.reading),
                    accent: Night.reading
                ) { engine.data.prefs.reading.strictness = $0 }
            }
        }
    }
}
