import SathiCore
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        Form {
            Section {
                TextField("Your name", text: $e.data.prefs.name)
            } header: {
                Text("You")
            }
            WaterSettingsSection(prefs: $e.data.prefs)
            ReadingSettingsSection(prefs: $e.data.prefs)
            ReminderSettingsSection(prefs: $e.data.prefs)
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
        .frame(width: UIMetrics.settingsSize.width, height: UIMetrics.settingsSize.height)
    }
}

struct TimeSlotPicker: View {
    let title: String
    @Binding var minutes: Int

    var body: some View {
        Picker(title, selection: $minutes) {
            ForEach(TimeSlots.all, id: \.minutes) { slot in Text(slot.label).tag(slot.minutes) }
        }
    }
}

struct StrictnessPicker: View {
    let title: String
    @Binding var value: Strictness

    var body: some View {
        Picker(title, selection: $value) {
            ForEach(Strictness.allCases) { s in Text(s.title).tag(s) }
        }
        Text(value.detail)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
