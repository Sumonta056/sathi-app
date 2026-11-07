import SathiCore
import SwiftUI

struct GymRhythmCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        SettingsCard {
            SettingRow(label: "Work hours", hint: "Popups spread evenly inside these hours.", showsDivider: false) {
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
