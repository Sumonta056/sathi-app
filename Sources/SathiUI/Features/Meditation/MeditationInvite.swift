import SathiCore
import SwiftUI

struct MeditationInvite: View {
    @EnvironmentObject var e: Engine
    let level: Level

    @State private var shakes: CGFloat = 0

    var body: some View {
        let prefs = e.data.prefs.meditation
        VStack(spacing: UIMetrics.calmSpacing) {
            Text("SHANTI · MEDITATION")
                .font(Typography.eyebrow)
                .foregroundStyle(Night.calm)
            BobbingBuddy(habit: .meditation, size: UIMetrics.calmInviteBuddySize)
            Text(e.copy(.meditation).title)
                .font(Typography.bubbleTitle)
                .foregroundStyle(Night.text)
                .multilineTextAlignment(.center)
            hint(Copywriter.meditationInviteHint(minutes: prefs.sessionMinutes, style: prefs.style))
            if level == .persist { hint(e.warnText(.meditation)) }
            buttons
        }
        .modifier(CalmCard(alert: level == .persist))
        .modifier(Shake(amount: shakes))
        .task(id: level) { await shakeWhilePersisting() }
    }

    private var buttons: some View {
        HStack(spacing: UIMetrics.calmButtonSpacing) {
            Button { e.startMeditation() } label: {
                Text("Breathe with me").frame(maxWidth: .infinity)
            }
            .buttonStyle(AccentButton(accent: Night.calm, height: UIMetrics.calmButtonHeight, text: Night.calmGround))
            Button { e.snooze(.meditation) } label: { Text(e.snoozeShortLabel) }
                .buttonStyle(GhostButton(
                    accent: Night.chipText,
                    height: UIMetrics.calmButtonHeight,
                    border: Night.heroBorder(.meditation)
                ))
        }
    }

    private func hint(_ text: String) -> some View {
        Text(text)
            .font(Typography.hint)
            .foregroundStyle(Night.muted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: UIMetrics.calmHintWidth)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func shakeWhilePersisting() async {
        guard level == .persist else { return }
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(UIMetrics.shakeInterval * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.linear(duration: UIMetrics.shakeDuration)) { shakes += 1 }
            if let s = ShakeSound.sound(for: .meditation) { e.play(s) }
        }
    }
}
