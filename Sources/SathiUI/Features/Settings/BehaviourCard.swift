import SathiCore
import ServiceManagement
import SwiftUI

struct BehaviourCard: View {
    @EnvironmentObject var e: Engine
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        SettingsCard {
            SettingRow(label: "Open Sathi when I log in", showsDivider: false) {
                BuddySwitch(isOn: loginBinding, accent: Night.sprout, label: "Open at login")
            }
            SettingRow(label: "Play soft sounds", hint: "A tiny pop when a buddy says hi.") {
                BuddySwitch(isOn: $e.data.prefs.general.soundOn, accent: Night.sprout, label: "Sounds")
            }
            SettingRow(label: "Stay quiet in meetings", hint: "Soon: buddies wait while the camera, mic, or a full-screen app is on.") {
                BuddySwitch(isOn: .constant(false), accent: Night.sprout, label: "Quiet in meetings")
                    .disabled(true)
            }
        }
    }

    private var loginBinding: Binding<Bool> {
        Binding(get: { launchAtLogin }, set: { setLaunchAtLogin($0) })
    }

    private func setLaunchAtLogin(_ on: Bool) {
        launchAtLogin = on
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
