import SwiftUI
import ServiceManagement

@MainActor
struct SettingsView: View {
    @EnvironmentObject var e: Engine
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    private let halfHours: [Int] = Array(stride(from: 0, to: 24 * 60, by: 30))
    private let sessionLengths = [10, 15, 20, 30, 45, 60]

    var body: some View {
        Form {
            Section {
                TextField("Your name", text: $e.data.prefs.name)
            } header: {
                Text("You")
            }

            Section {
                Toggle("Remind me to drink water", isOn: $e.data.prefs.waterEnabled)
                Stepper("Every \(intervalText)", value: $e.data.prefs.waterIntervalMinutes, in: 15...240, step: 15)
                Picker("From", selection: $e.data.prefs.waterStartMinutes) {
                    ForEach(halfHours, id: \.self) { m in Text(Fmt.timeOfDay(m)).tag(m) }
                }
                Picker("Until", selection: $e.data.prefs.waterEndMinutes) {
                    ForEach(halfHours, id: \.self) { m in Text(Fmt.timeOfDay(m)).tag(m) }
                }
                Picker("I usually drink from", selection: $e.data.prefs.defaultContainer) {
                    Text("Glass").tag(Container.glass)
                    Text("Sip bottle").tag(Container.bottle)
                }
                Stepper("My bottle holds about \(Fmt.count(e.data.prefs.bottleSizeGlasses)) glasses",
                        value: $e.data.prefs.bottleSizeGlasses, in: 1...6, step: 0.5)
                Stepper("Daily goal: \(Int(e.data.prefs.dailyGoalGlasses)) glasses",
                        value: $e.data.prefs.dailyGoalGlasses, in: 4...16, step: 1)
                Picker("When I ignore Fota", selection: $e.data.prefs.waterStrictness) {
                    ForEach(Strictness.allCases) { s in Text(s.title).tag(s) }
                }
                Text(e.data.prefs.waterStrictness.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Water · Fota")
            }

            Section {
                Toggle("Remind me to read", isOn: $e.data.prefs.readingEnabled)
                Picker("Remind me at", selection: $e.data.prefs.readingTimeMinutes) {
                    ForEach(halfHours, id: \.self) { m in Text(Fmt.timeOfDay(m)).tag(m) }
                }
                Picker("Reading session", selection: $e.data.prefs.readingSessionMinutes) {
                    ForEach(sessionLengths, id: \.self) { m in Text("\(m) min").tag(m) }
                }
                Picker("When I ignore Boi", selection: $e.data.prefs.readingStrictness) {
                    ForEach(Strictness.allCases) { s in Text(s.title).tag(s) }
                }
                Text(e.data.prefs.readingStrictness.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Reading · Boi")
            }

            Section {
                Stepper("Snooze for \(e.data.prefs.snoozeMinutes) min", value: $e.data.prefs.snoozeMinutes, in: 1...30)
                Stepper("Ignoring counts as a snooze after \(e.data.prefs.ignoreMinutes) min",
                        value: $e.data.prefs.ignoreMinutes, in: 1...15)
                Toggle("Play a sound when a buddy pops up", isOn: $e.data.prefs.soundOn)
                Toggle("Open Sathi when my Mac starts", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { on in
                        do {
                            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
                        } catch {
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
            } header: {
                Text("Reminders")
            }

            Section {
                HStack {
                    Button("Show water reminder now") { e.trigger(.water) }
                    Button("Show reading reminder now") { e.trigger(.reading) }
                }
            } header: {
                Text("Try it")
            } footer: {
                Text("Snooze twice on the water reminder to see the lock screen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 540, height: 680)
    }

    private var intervalText: String {
        let m = e.data.prefs.waterIntervalMinutes
        if m % 60 == 0 { return m == 60 ? "1 hour" : "\(m / 60) hours" }
        return m > 60 ? "\(m / 60) h \(m % 60) min" : "\(m) min"
    }
}
