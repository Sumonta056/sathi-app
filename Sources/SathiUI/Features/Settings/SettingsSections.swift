import SathiCore
import ServiceManagement
import SwiftUI

struct WaterSettingsSection: View {
    @Binding var prefs: Prefs

    var body: some View {
        Section {
            Toggle("Remind me to drink water", isOn: $prefs.water.enabled)
            Stepper(
                "Every \(Fmt.interval(minutes: prefs.water.intervalMinutes))",
                value: $prefs.water.intervalMinutes,
                in: Limits.waterIntervalMinutes,
                step: Limits.waterIntervalStep
            )
            TimeSlotPicker(title: "From", minutes: $prefs.water.startMinutes)
            TimeSlotPicker(title: "Until", minutes: $prefs.water.endMinutes)
            Picker("I usually drink from", selection: $prefs.water.container) {
                Text("Glass").tag(Container.glass)
                Text("Sip bottle").tag(Container.bottle)
            }
            Stepper(
                "My bottle holds about \(Fmt.count(prefs.water.bottleSizeGlasses)) glasses",
                value: $prefs.water.bottleSizeGlasses,
                in: Limits.bottleSizeGlasses,
                step: Limits.bottleSizeStep
            )
            Stepper(
                "Daily goal: \(Int(prefs.water.dailyGoalGlasses)) glasses",
                value: $prefs.water.dailyGoalGlasses,
                in: Limits.dailyGoalGlasses,
                step: 1
            )
            StrictnessPicker(title: "When I ignore Fota", value: $prefs.water.strictness)
        } header: {
            Text("Water · Fota")
        }
    }
}

struct ReadingSettingsSection: View {
    @Binding var prefs: Prefs

    var body: some View {
        Section {
            Toggle("Remind me to read", isOn: $prefs.reading.enabled)
            TimeSlotPicker(title: "Remind me at", minutes: $prefs.reading.timeMinutes)
            Picker("Reading session", selection: $prefs.reading.sessionMinutes) {
                ForEach(Limits.sessionLengths, id: \.self) { m in Text("\(m) min").tag(m) }
            }
            StrictnessPicker(title: "When I ignore Boi", value: readingStrictness, options: [.friendly, .persistent])
        } header: {
            Text("Reading · Boi")
        }
    }

    private var readingStrictness: Binding<Strictness> {
        Binding(get: { prefs.strictness(.reading) }, set: { prefs.reading.strictness = $0 })
    }
}

struct ReminderSettingsSection: View {
    @Binding var prefs: Prefs
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Section {
            Stepper("Snooze for \(prefs.general.snoozeMinutes) min", value: $prefs.general.snoozeMinutes, in: Limits.snoozeMinutes)
            Stepper(
                "Ignoring counts as a snooze after \(prefs.general.ignoreMinutes) min",
                value: $prefs.general.ignoreMinutes,
                in: Limits.ignoreMinutes
            )
            Toggle("Play a sound when a buddy pops up", isOn: $prefs.general.soundOn)
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
