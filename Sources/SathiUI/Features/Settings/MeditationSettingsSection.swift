import SathiCore
import SwiftUI

struct MeditationSettingsSection: View {
    @EnvironmentObject var e: Engine

    private static let slotLabels: [MeditationSlot: String] = Dictionary(uniqueKeysWithValues: MeditationSlot.allCases.map {
        ($0, "\($0.rawValue.capitalized) · \(Fmt.timeOfDay($0.minutes))")
    })

    var body: some View {
        Section {
            Toggle("Remind me to meditate", isOn: $e.data.prefs.meditation.enabled)
            ForEach(MeditationSlot.allCases, id: \.self) { slot in
                Toggle(Self.slotLabels[slot] ?? slot.rawValue, isOn: binding(slot))
            }
            Picker("Breathing session", selection: $e.data.prefs.meditation.sessionMinutes) {
                ForEach(Limits.meditationLengths, id: \.self) { m in Text("\(m) min").tag(m) }
            }
            Picker("Breathing style", selection: $e.data.prefs.meditation.style) {
                ForEach(BreathingStyle.allCases, id: \.self) { s in Text(Self.styleTitle(s)).tag(s) }
            }
            Toggle("Soft chime at the end", isOn: $e.data.prefs.meditation.chime)
            Button("Show meditation reminder now") { e.trigger(.meditation) }
                .disabled(!e.data.prefs.meditation.enabled)
        } header: {
            HStack(spacing: 6) {
                Text("Meditation · Shanti")
                Text("New")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Palette.calmDeep))
            }
        }
    }

    private func binding(_ slot: MeditationSlot) -> Binding<Bool> {
        Binding(
            get: { e.data.prefs.meditation.slots.contains(slot) },
            set: { on in
                if on { e.data.prefs.meditation.slots.insert(slot) } else { e.data.prefs.meditation.slots.remove(slot) }
            }
        )
    }

    private static func styleTitle(_ s: BreathingStyle) -> String {
        let counts = BreathingPattern.steps(s).map { "\(Int($0.1))" }.joined(separator: "-")
        return "\(s.rawValue.capitalized) (\(counts))"
    }
}
