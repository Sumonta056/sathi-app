import SathiCore
import SwiftUI

struct ReadingSettingsTab: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        HabitSettingsPage(habit: .reading) {
            SettingsSection("When") { ReadingWhenCard() }
            SettingsSection("What to read") { ReadingListCard() }
            DaysOffCard(habit: .reading)
            SettingsSection("How Boi says hi") { ReadingStyleCards() }
            SettingsSection("If I ignore Boi") {
                StrictnessCards(
                    options: Strictness.allCases,
                    selected: engine.data.prefs.strictness(.reading),
                    accent: Night.reading
                ) { engine.data.prefs.reading.strictness = $0 }
                CloseButtonCard(habit: .reading)
            }
        }
    }
}
