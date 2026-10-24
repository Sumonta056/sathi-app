import SathiCore
import SwiftUI

struct MeditationWhenCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        let med = engine.data.prefs.meditation
        SettingsCard {
            SettingRow(label: "Remind me in the", hint: "Pick one or more.", showsDivider: false) {
                ChipRow(
                    options: MeditationSlot.allCases,
                    accent: Night.calm,
                    isSelected: { med.slots.contains($0) },
                    onTap: { engine.data.prefs.meditation.slots = med.slots.togglingKeepingOne($0) },
                    label: Self.label
                )
            }
            SettingRow(label: "Session length") {
                ChipRow(
                    options: Limits.meditationLengths,
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

    static func label(_ slot: MeditationSlot) -> String {
        switch slot {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        }
    }
}
