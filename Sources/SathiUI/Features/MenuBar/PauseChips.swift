import SathiCore
import SwiftUI

struct PauseChips: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.chipSpacing) {
            Text("Take a break from reminders")
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
            HStack(spacing: UIMetrics.chipSpacing) {
                chip("30 min") { e.pause(hours: Timing.shortPauseHours) }
                chip("1 hour") { e.pause(hours: Timing.defaultPauseHours) }
                chip("Rest of day") { e.pauseRestOfDay() }
            }
        }
    }

    private func chip(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).frame(maxWidth: .infinity)
        }
        .buttonStyle(GhostButton(accent: Night.chipText, height: UIMetrics.pauseChipHeight))
    }
}
