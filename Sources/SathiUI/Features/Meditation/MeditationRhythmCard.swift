import SathiCore
import SwiftUI

struct MeditationRhythmCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        SettingsCard {
            IntervalRow(minutes: $e.data.prefs.meditation.intervalMinutes, accent: Night.calm)
            SettingRow(label: "Between", hint: "Shanti rests outside these hours.") {
                HStack(spacing: UIMetrics.chipSpacing) {
                    TimeMenu(minutes: $e.data.prefs.meditation.startMinutes, accent: Night.calm)
                    Text(verbatim: "to")
                        .font(Typography.hint)
                        .foregroundStyle(Night.muted)
                    TimeMenu(minutes: $e.data.prefs.meditation.endMinutes, accent: Night.calm)
                }
            }
            SettingRow(label: "On these days") {
                WeekdayRow(habit: .meditation)
            }
        }
    }
}
