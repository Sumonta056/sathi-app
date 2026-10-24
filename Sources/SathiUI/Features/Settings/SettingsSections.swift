import SathiCore
import ServiceManagement
import SwiftUI

struct WaterSettingsSection: View {
    @Binding var prefs: Prefs

    var body: some View {
        Section {
            Toggle("Remind me to drink water", isOn: $prefs.waterEnabled)
            Stepper(
                "Every \(Fmt.interval(minutes: prefs.waterIntervalMinutes))",
                value: $prefs.waterIntervalMinutes,
                in: Limits.waterIntervalMinutes,
                step: Limits.waterIntervalStep
            )
            TimeSlotPicker(title: "From", minutes: $prefs.waterStartMinutes)
            TimeSlotPicker(title: "Until", minutes: $prefs.waterEndMinutes)
            Picker("I usually drink from", selection: $prefs.defaultContainer) {
                Text("Glass").tag(Container.glass)
                Text("Sip bottle").tag(Container.bottle)
            }
            Stepper(
                "My bottle holds about \(Fmt.count(prefs.bottleSizeGlasses)) glasses",
                value: $prefs.bottleSizeGlasses,
                in: Limits.bottleSizeGlasses,
                step: Limits.bottleSizeStep
            )
            Stepper(
                "Daily goal: \(Int(prefs.dailyGoalGlasses)) glasses",
                value: $prefs.dailyGoalGlasses,
                in: Limits.dailyGoalGlasses,
                step: 1
            )
            StrictnessPicker(title: "When I ignore Fota", value: $prefs.waterStrictness)
        } header: {
            Text("Water · Fota")
        }
    }
}

struct ReadingSettingsSection: View {
    @Binding var prefs: Prefs

    var body: some View {
        Section {
            Toggle("Remind me to read", isOn: $prefs.readingEnabled)
            TimeSlotPicker(title: "Remind me at", minutes: $prefs.readingTimeMinutes)
            Picker("Reading session", selection: $prefs.readingSessionMinutes) {
                ForEach(Limits.sessionLengths, id: \.self) { m in Text("\(m) min").tag(m) }
            }
            StrictnessPicker(title: "When I ignore Boi", value: $prefs.readingStrictness)
        } header: {
            Text("Reading · Boi")
        }
    }
}

struct ReminderSettingsSection: View {
    @Binding var prefs: Prefs
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Section {
            Stepper("Snooze for \(prefs.snoozeMinutes) min", value: $prefs.snoozeMinutes, in: Limits.snoozeMinutes)
            Stepper(
                "Ignoring counts as a snooze after \(prefs.ignoreMinutes) min",
                value: $prefs.ignoreMinutes,
                in: Limits.ignoreMinutes
            )
            Toggle("Play a sound when a buddy pops up", isOn: $prefs.soundOn)
            Toggle("Open Sathi when my Mac starts", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { on in setLaunchAtLogin(on) }
        } header: {
            Text("Reminders")
        }
    }

    private func setLaunchAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
