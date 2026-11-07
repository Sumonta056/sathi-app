import SathiCore
import SwiftUI

struct MeditationSoundCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        SettingsCard {
            SettingRow(label: "Voice guide", hint: "Shanti says each phase once. She never counts.", showsDivider: false) {
                controls(isOn: $e.data.prefs.meditation.voiceOn, volume: $e.data.prefs.meditation.voiceVolume, name: "Voice guide")
            }
            SettingRow(label: "Music", hint: "Plays softly under the voice.") {
                controls(isOn: $e.data.prefs.meditation.musicOn, volume: $e.data.prefs.meditation.musicVolume, name: "Music")
            }
            SettingRow(label: "Soft bell at start and end") {
                BuddySwitch(isOn: $e.data.prefs.meditation.chime, accent: Night.calm, label: "Soft bell at start and end")
            }
            SettingRow(label: "Soft tick every minute") {
                BuddySwitch(isOn: $e.data.prefs.meditation.minuteTick, accent: Night.calm, label: "Soft tick every minute")
            }
            SettingRow(label: "Preview") {
                Button("Preview") { engine.previewSessionSound() }
                    .buttonStyle(GhostButton(accent: Night.calm))
                    .disabled(!engine.data.prefs.general.soundOn)
            }
        }
    }

    private func controls(isOn: Binding<Bool>, volume: Binding<Double>, name: String) -> some View {
        HStack(spacing: UIMetrics.chipSpacing) {
            if isOn.wrappedValue {
                VolumeSlider(value: volume, accent: Night.calm, label: "\(name) volume")
            }
            BuddySwitch(isOn: isOn, accent: Night.calm, label: name)
        }
    }
}
