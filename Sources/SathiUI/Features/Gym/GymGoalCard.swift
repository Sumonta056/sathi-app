import SathiCore
import SwiftUI

struct GymGoalCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        let gym = engine.data.prefs.gym
        SettingsCard {
            SettingRow(label: "Sessions a day", hint: "Shokti stops for the day when you reach the goal.", showsDivider: false) {
                ChipRow(
                    options: Limits.gymSessionCounts,
                    accent: Night.gym,
                    isSelected: { $0 == gym.sessionsPerDay },
                    onTap: { engine.data.prefs.gym.sessionsPerDay = $0 },
                    label: { "\($0)" }
                )
            }
            SettingRow(label: "Each session") {
                ChipRow(
                    options: Limits.gymSessionLengths,
                    accent: Night.gym,
                    isSelected: { $0 == gym.sessionMinutes },
                    onTap: { engine.data.prefs.gym.sessionMinutes = $0 },
                    label: { "\($0) min" }
                )
            }
            summary(gym)
        }
    }

    private func summary(_ gym: GymPrefs) -> some View {
        VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
            Text(verbatim: Copywriter.gymGoalSummary(gym))
                .font(Typography.chip)
                .foregroundStyle(Night.gym)
            if !gym.popupMinutes.isEmpty {
                Text(verbatim: Copywriter.gymPopupTimes(gym))
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(UIMetrics.rowPadding)
        .overlay(alignment: .top) {
            Rectangle().fill(Night.divider).frame(height: UIMetrics.dividerHeight)
        }
    }
}
