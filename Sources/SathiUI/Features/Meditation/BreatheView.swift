import SathiCore
import SwiftUI

struct BreatheView: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let style = e.data.prefs.meditation.style
        let minutes = Int((e.sessionEnd.timeIntervalSince(e.sessionStart) / Timing.minute).rounded())
        let elapsed = max(0, e.now.timeIntervalSince(e.sessionStart))
        let phase = BreathingPattern.step(style, at: elapsed).phase
        let queued = e.queue.contains(.water)
        VStack(spacing: UIMetrics.calmSpacing) {
            Text(Copywriter.breathHeader(style))
                .font(Typography.eyebrow)
                .foregroundStyle(Night.calm)
            BreathCircle(style: style, start: e.sessionStart)
            Text(Copywriter.breathLabel(phase))
                .font(Typography.breathPhase)
                .foregroundStyle(Night.text)
            Text(Copywriter.breathRound(
                BreathingPattern.round(style, elapsed: elapsed, minutes: minutes),
                of: BreathingPattern.totalRounds(style, minutes: minutes)
            ))
            .font(Typography.hint)
            .foregroundStyle(Night.muted)
            waterNote(queued)
                .frame(height: UIMetrics.calmNoteHeight)
            Button { e.stopSession() } label: { Text("Stop") }
                .buttonStyle(GhostButton(
                    accent: Night.chipText,
                    height: UIMetrics.calmButtonHeight,
                    border: Night.heroBorder(.meditation)
                ))
        }
        .modifier(CalmCard())
    }

    @ViewBuilder
    private func waterNote(_ queued: Bool) -> some View {
        if queued {
            Text("Fota is waiting for you after this")
                .font(Typography.hint)
                .foregroundStyle(Night.water)
        } else {
            Color.clear.accessibilityHidden(true)
        }
    }
}
