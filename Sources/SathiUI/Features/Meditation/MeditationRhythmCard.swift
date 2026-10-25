import SathiCore
import SwiftUI

struct MeditationRhythmCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        let med = engine.data.prefs.meditation
        SettingsCard {
            SettingRow(label: "Remind me every", showsDivider: false) {
                ChipRow(
                    options: Limits.meditationIntervalChips,
                    accent: Night.calm,
                    isSelected: { $0 == med.intervalMinutes },
                    onTap: { engine.data.prefs.meditation.intervalMinutes = $0 },
                    label: { "\($0) min" }
                )
            }
            SettingRow(label: "Between", hint: "Shanti rests outside these hours.") {
                HStack(spacing: UIMetrics.chipSpacing) {
                    TimeMenu(minutes: $e.data.prefs.meditation.startMinutes, accent: Night.calm)
                    Text(verbatim: "to")
                        .font(Typography.hint)
                        .foregroundStyle(Night.muted)
                    TimeMenu(minutes: $e.data.prefs.meditation.endMinutes, accent: Night.calm)
                }
            }
        }
    }
}
