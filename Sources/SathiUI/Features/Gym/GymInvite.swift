import SathiCore
import SwiftUI

struct GymInvite: View {
    @EnvironmentObject var e: Engine
    let level: Level

    @State private var shakes: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.cornerSpacing) {
            header
            GymProgressBar(progress: e.gymProgress)
            HStack(spacing: UIMetrics.cornerButtonSpacing) {
                Button { e.startSession(.gym) } label: {
                    Text("Start").frame(maxWidth: .infinity)
                }
                .buttonStyle(AccentButton(accent: Night.gym, height: UIMetrics.cornerButtonHeight))
                Button { e.nextGymIdea() } label: {
                    Image(systemName: "shuffle")
                        .font(.system(size: UIMetrics.gymIconSize, weight: .bold))
                        .foregroundStyle(Night.gym)
                        .frame(width: UIMetrics.cornerButtonHeight)
                }
                .buttonStyle(ghost)
                .accessibilityLabel(Text(verbatim: "Next idea"))
                if e.canSnooze(.gym) {
                    Button { e.snooze(.gym) } label: { Text(e.snoozeShortLabel) }
                        .buttonStyle(ghost)
                }
            }
            if !e.canSnooze(.gym) { SkipTodayButton(id: .gym) }
            if level == .persist {
                Text(e.warnText(.gym))
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .modifier(CornerCard(alert: level == .persist, habit: .gym))
        .modifier(Shake(amount: shakes))
        .task(id: level) { await shakeWhilePersisting() }
    }

    private var ghost: GhostButton {
        GhostButton(accent: Night.chipText, height: UIMetrics.cornerButtonHeight, border: Night.heroBorder(.gym))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: UIMetrics.cornerRowSpacing) {
            BobbingBuddy(habit: .gym, size: UIMetrics.cornerBuddySize)
            VStack(alignment: .leading, spacing: UIMetrics.cornerTextSpacing) {
                Text("SHOKTI · GYM")
                    .font(Typography.eyebrow)
                    .foregroundStyle(Night.gym)
                Text(verbatim: Copywriter.gymInviteTitle(idea: e.gymIdeaText, name: e.data.prefs.general.name))
                    .font(Typography.cornerTitle)
                    .foregroundStyle(Night.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: Copywriter.gymInviteLine(minutes: e.data.prefs.gym.sessionMinutes))
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if e.showsClose(.gym, level: level) {
                CornerCloseButton(label: "Dismiss") { e.snooze(.gym) }
            }
        }
    }

    private func shakeWhilePersisting() async {
        guard level == .persist else { return }
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(UIMetrics.shakeInterval * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.linear(duration: UIMetrics.shakeDuration)) { shakes += 1 }
            if let s = ShakeSound.sound(for: .gym) { e.play(s) }
        }
    }
}
