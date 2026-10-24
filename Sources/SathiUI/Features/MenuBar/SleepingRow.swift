import SathiCore
import SwiftUI

struct SleepingRow: View {
    @EnvironmentObject var e: Engine
    let id: HabitID

    var body: some View {
        HStack(spacing: UIMetrics.menuSpacing) {
            Text("\(id.name) is sleeping")
                .font(Typography.rowLabel)
                .foregroundStyle(Night.muted)
            Spacer()
            Button("Turn on") { e.enabledBinding(id).wrappedValue = true }
                .buttonStyle(GhostButton(accent: Night.sprout, height: UIMetrics.actionHeight))
        }
        .padding(UIMetrics.cardPadding)
        .overlay(
            RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
                .strokeBorder(Night.fieldBorder, style: StrokeStyle(lineWidth: UIMetrics.cardBorder, dash: [UIMetrics.dashLength]))
        )
    }
}
