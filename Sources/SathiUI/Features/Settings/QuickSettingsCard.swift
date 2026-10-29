import SathiCore
import SwiftUI

struct QuickSettingsCard: View {
    @EnvironmentObject var e: Engine

    static let label = "Show a close button"

    var body: some View {
        let engine = e
        SettingsSection("Quick reminders") {
            StrictnessCards(
                options: Strictness.allCases,
                selected: engine.quickStrictness.wrappedValue,
                accent: Night.quick
            ) { engine.quickStrictness.wrappedValue = $0 }
            SettingsCard {
                SettingRow(label: Self.label, hint: "A tap on it snoozes the reminder.", showsDivider: false) {
                    BuddySwitch(isOn: engine.quickShowsClose, accent: Night.quick, label: Self.label)
                }
            }
        }
    }
}
