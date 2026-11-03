import SathiCore
import SwiftUI

struct CloseButtonCard: View {
    @EnvironmentObject var e: Engine
    let habit: HabitID

    static let label = "Show a close button"

    static func hint(_ id: HabitID) -> String {
        "A tap on it snoozes \(id.buddy). It hides after a snooze at Nudgy and Strict."
    }

    var body: some View {
        SettingsCard {
            SettingRow(label: Self.label, hint: Self.hint(habit), showsDivider: false) {
                BuddySwitch(isOn: e.closeButtonBinding(habit), accent: Night.accent(habit), label: Self.label)
            }
        }
    }
}
