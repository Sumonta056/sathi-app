import SathiCore
import SwiftUI

struct BreakMenu: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        Menu {
            Button("30 min") { e.pause(hours: Timing.shortPauseHours) }
            Button("1 hour") { e.pause(hours: Timing.defaultPauseHours) }
            Button("Rest of day") { e.pauseRestOfDay() }
            if !e.quickReminders.isEmpty {
                Divider()
                Text(verbatim: "Quick reminders still show during a break.")
            }
        } label: {
            HStack(spacing: UIMetrics.chipSpacing) {
                Image(systemName: "pause.fill")
                    .accessibilityHidden(true)
                Text(verbatim: "Take a break")
            }
            .font(Typography.chip)
            .foregroundStyle(Night.chipText)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.visible)
        .fixedSize()
        .padding(.horizontal, UIMetrics.chipPadding)
        .frame(height: UIMetrics.breakMenuHeight)
        .overlay(
            RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
                .strokeBorder(Night.fieldBorder, lineWidth: UIMetrics.cardBorder)
        )
    }
}
