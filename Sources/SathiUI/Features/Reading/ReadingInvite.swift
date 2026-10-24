import SathiCore
import SwiftUI

struct ReadingInvite: View {
    @EnvironmentObject var e: Engine
    let level: Level

    @State private var shakes: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.cornerSpacing) {
            header
            HStack(spacing: UIMetrics.cornerButtonSpacing) {
                Button { e.startReading() } label: {
                    Text("Start reading").frame(maxWidth: .infinity)
                }
                .buttonStyle(AccentButton(accent: Night.reading, height: UIMetrics.cornerButtonHeight))
                Button { e.snooze() } label: { Text(e.snoozeShortLabel) }
                    .buttonStyle(GhostButton(accent: Night.chipText, height: UIMetrics.cornerButtonHeight))
            }
            if level == .persist {
                Text(e.warnText(.reading))
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .modifier(CornerCard(alert: level == .persist))
        .modifier(Shake(amount: shakes))
        .task(id: level) { await shakeWhilePersisting() }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: UIMetrics.cornerRowSpacing) {
            BobbingBuddy(habit: .reading, size: UIMetrics.cornerBuddySize)
            VStack(alignment: .leading, spacing: UIMetrics.cornerTextSpacing) {
                Text("BOI · READING")
                    .font(Typography.eyebrow)
                    .foregroundStyle(Night.reading)
                Text(e.copy.title)
                    .font(Typography.cornerTitle)
                    .foregroundStyle(Night.text)
                Text(Copywriter.readingInviteHint(minutes: e.data.prefs.reading.sessionMinutes))
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if level == .nudge {
                CornerCloseButton(label: "Dismiss") { e.snooze() }
            }
        }
    }

    private func shakeWhilePersisting() async {
        guard level == .persist else { return }
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(UIMetrics.shakeInterval * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.linear(duration: UIMetrics.shakeDuration)) { shakes += 1 }
            if let s = ShakeSound.sound(for: .reading) { e.play(s) }
        }
    }
}
