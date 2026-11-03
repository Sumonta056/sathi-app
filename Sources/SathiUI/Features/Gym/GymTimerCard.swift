import SathiCore
import SwiftUI

struct GymTimerCard: View {
    @EnvironmentObject var e: Engine

    static func progress(start: Date, end: Date, now: Date) -> Double {
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return min(1, max(0, now.timeIntervalSince(start) / total))
    }

    var body: some View {
        let s = e.session(.gym) ?? Session(start: e.now, end: e.now)
        VStack(alignment: .leading, spacing: UIMetrics.cornerSpacing) {
            HStack(alignment: .top, spacing: UIMetrics.cornerRowSpacing) {
                BobbingBuddy(habit: .gym, size: UIMetrics.cornerBuddySize)
                VStack(alignment: .leading, spacing: UIMetrics.cornerTextSpacing) {
                    Text("SHOKTI · \(e.gymWorkout.name)")
                        .font(Typography.eyebrow)
                        .foregroundStyle(Night.gym)
                    Text(Copywriter.gymTimerLine())
                        .font(Typography.cornerTitle)
                        .foregroundStyle(Night.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(timerInterval: e.now ... max(e.now, s.end), countsDown: true)
                        .font(Typography.pillTime)
                        .foregroundStyle(Night.gym)
                }
                Spacer(minLength: 0)
            }
            ProgressBar(
                value: Self.progress(start: s.start, end: s.end, now: e.now),
                tint: Night.gym,
                height: UIMetrics.gymProgressHeight,
                track: Night.fieldBorder
            )
            HStack(spacing: UIMetrics.cornerButtonSpacing) {
                Button { e.finishSession(.gym) } label: {
                    Text("Done").frame(maxWidth: .infinity)
                }
                .buttonStyle(AccentButton(accent: Night.gym, height: UIMetrics.cornerButtonHeight))
                Button { e.stopSession(.gym) } label: { Text("Stop") }
                    .buttonStyle(GhostButton(
                        accent: Night.chipText,
                        height: UIMetrics.cornerButtonHeight,
                        border: Night.heroBorder(.gym)
                    ))
            }
        }
        .modifier(CornerCard(habit: .gym))
    }
}
