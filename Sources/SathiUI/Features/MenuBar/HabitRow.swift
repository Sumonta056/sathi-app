import SathiCore
import SwiftUI

struct HabitRow: View {
    @EnvironmentObject var e: Engine
    let id: HabitID

    var body: some View {
        HStack(spacing: 12) {
            BuddyView(kind: id.kind, mood: e.mood(id), level: e.waterLevel)
                .frame(width: 44, height: 54)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(id.name).font(.system(size: 15, weight: .semibold, design: .rounded))
                    Spacer()
                    pill
                }
                ProgressBar(value: e.progress(id), tint: Palette.accent(id))
                Text(e.subtitle(id))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Button(id == .water ? "+1 glass" : "Read now") {
                MenuBarWindow.close()
                if id == .water { e.logWater(1) } else { e.startReading() }
            }
            .buttonStyle(MiniButton())
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.05)))
    }

    private var pill: some View {
        let due = e.isDue(id)
        return Text(e.pill(id))
            .font(.system(size: 11, weight: .semibold))
            .monospacedDigit()
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .foregroundStyle(due ? Color.white : Color.secondary)
            .background(Capsule().fill(due ? Palette.deep(id) : Color.primary.opacity(0.07)))
    }
}
