import SathiCore
import SwiftUI

struct ReadingWhenCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        let reading = engine.data.prefs.reading
        SettingsCard {
            SettingRow(label: "Remind me at", showsDivider: false) {
                TimeMenu(minutes: $e.data.prefs.reading.timeMinutes)
            }
            SettingRow(label: "On these days") {
                ChipRow(
                    options: Weekday.allCases,
                    accent: Night.reading,
                    isSelected: { reading.weekdays.contains($0) },
                    onTap: { engine.data.prefs.reading.weekdays = reading.weekdays.togglingKeepingOne($0) },
                    label: \.shortLabel,
                    spokenLabel: \.name
                )
            }
            SettingRow(label: "Session length") {
                ChipRow(
                    options: Limits.sessionLengths,
                    accent: Night.reading,
                    isSelected: { $0 == reading.sessionMinutes },
                    onTap: { engine.data.prefs.reading.sessionMinutes = $0 },
                    label: { "\($0) min" }
                )
            }
        }
    }
}
