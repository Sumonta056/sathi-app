import SathiCore
import SwiftUI

struct GymRhythmCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        SettingsCard {
            IntervalRow(minutes: $e.data.prefs.gym.intervalMinutes, accent: Night.gym)
            SettingRow(label: "Work hours", hint: "Shokti sleeps outside these hours.") {
                HStack(spacing: UIMetrics.chipSpacing) {
                    TimeMenu(minutes: $e.data.prefs.gym.startMinutes, accent: Night.gym)
                    Text(verbatim: "to")
                        .font(Typography.hint)
                        .foregroundStyle(Night.muted)
                    TimeMenu(minutes: $e.data.prefs.gym.endMinutes, accent: Night.gym)
                }
            }
            SettingRow(label: "Work days") {
                WeekdayRow(habit: .gym)
            }
        }
    }
}
