import SathiCore
import SwiftUI

struct SoundPage: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.pageSpacing) {
            SettingsCard {
                SettingRow(label: Copywriter.settingsSoftSounds, hint: Copywriter.settingsSoftSoundsHint, showsDivider: false) {
                    BuddySwitch(isOn: $e.data.prefs.general.soundOn, accent: Night.sprout, label: "Sounds")
                }
            }
            MeditationSoundCard()
        }
    }
}
