import SathiCore
import SwiftUI

struct TrackerMoreCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        SettingsSection(Copywriter.trackerMore) {
            SettingsCard {
                TrackerShortcutRow()
                SettingRow(label: Copywriter.trackerEndOfDayLabel, hint: Copywriter.trackerEndOfDayHint(engine.trackerEndMinutes.wrappedValue)) {
                    BuddySwitch(isOn: engine.trackerEndOfDay, accent: Night.tracker, label: Copywriter.trackerEndOfDayLabel)
                        .accessibilityIdentifier("settings.tracker.endofday")
                }
                SettingRow(label: Copywriter.trackerSoundLabel, hint: Copywriter.trackerSoundHint) {
                    BuddySwitch(isOn: engine.trackerSound, accent: Night.tracker, label: Copywriter.trackerSoundLabel)
                        .accessibilityIdentifier("settings.tracker.sound")
                }
            }
        }
    }
}
