import SathiCore
import SwiftUI

struct GymRhythmCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        let gym = engine.data.prefs.gym
        SettingsCard {
            SettingRow(label: "Remind me every", showsDivider: false) {
                ChipRow(
                    options: Limits.gymIntervalChips,
                    accent: Night.gym,
                    isSelected: { $0 == gym.intervalMinutes },
                    onTap: { engine.data.prefs.gym.intervalMinutes = $0 },
                    label: { "\($0) min" }
                )
            }
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
                ChipRow(
                    options: Weekday.allCases,
                    accent: Night.gym,
                    isSelected: { gym.weekdays.contains($0) },
                    onTap: { engine.data.prefs.gym.weekdays = gym.weekdays.togglingKeepingOne($0) },
                    label: \.shortLabel,
                    spokenLabel: \.name
                )
            }
        }
    }
}
