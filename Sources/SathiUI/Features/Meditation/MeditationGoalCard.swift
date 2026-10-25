import SathiCore
import SwiftUI

struct MeditationGoalCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        let med = engine.data.prefs.meditation
        SettingsCard {
            SettingRow(label: "Daily goal", hint: "Shanti stops for the day when you reach it.", showsDivider: false) {
                ChipRow(
                    options: Self.options(Limits.meditationGoals, keeping: med.dailyGoalMinutes),
                    accent: Night.calm,
                    isSelected: { $0 == med.dailyGoalMinutes },
                    onTap: { engine.data.prefs.meditation.dailyGoalMinutes = $0 },
                    label: { "\($0) min" }
                )
            }
            SettingRow(label: "Each session") {
                ChipRow(
                    options: Self.options(Limits.meditationLengths, keeping: med.sessionMinutes),
                    accent: Night.calm,
                    isSelected: { $0 == med.sessionMinutes },
                    onTap: { engine.data.prefs.meditation.sessionMinutes = $0 },
                    label: { "\($0) min" }
                )
            }
            SettingRow(label: "Soft chime at the end") {
                BuddySwitch(isOn: $e.data.prefs.meditation.chime, accent: Night.calm, label: "Chime")
            }
        }
    }

    static func options(_ chips: [Int], keeping saved: Int) -> [Int] {
        chips.contains(saved) ? chips : (chips + [saved]).sorted()
    }
}
