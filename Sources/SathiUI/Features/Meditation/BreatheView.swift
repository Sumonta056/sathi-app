import SathiCore
import SwiftUI

struct BreatheView: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let style = e.data.prefs.meditation.style
        let s = e.session(.meditation) ?? Session(start: e.now, end: e.now)
        let minutes = Int((s.end.timeIntervalSince(s.start) / Timing.minute).rounded())
        let elapsed = max(0, e.now.timeIntervalSince(s.start))
        let phase = BreathingPattern.step(style, at: elapsed).phase
        VStack(spacing: UIMetrics.calmSpacing) {
            Text(Copywriter.breathHeader(style))
                .font(Typography.eyebrow)
                .foregroundStyle(Night.calm)
            BreathCircle(style: style, start: s.start)
            Text(Copywriter.breathLabel(phase))
                .font(Typography.breathPhase)
                .foregroundStyle(Night.text)
            Text(Copywriter.breathRound(
                BreathingPattern.round(style, elapsed: elapsed, minutes: minutes),
                of: BreathingPattern.totalRounds(style, minutes: minutes)
            ))
            .font(Typography.hint)
            .foregroundStyle(Night.muted)
            Button { e.stopSession(.meditation) } label: { Text("Stop") }
                .buttonStyle(GhostButton(
                    accent: Night.chipText,
                    height: UIMetrics.calmButtonHeight,
                    border: Night.heroBorder(.meditation)
                ))
        }
        .modifier(CalmCard())
    }
}
