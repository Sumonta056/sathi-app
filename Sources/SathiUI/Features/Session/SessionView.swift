import SathiCore
import SwiftUI

struct SessionView: View {
    @EnvironmentObject var e: Engine
    let id: HabitID

    var body: some View {
        if let s = e.session(id) { content(s) }
    }

    private func content(_ s: Session) -> some View {
        TimelineView(.periodic(from: .now, by: UIMetrics.sessionRefresh)) { tl in
            let total = max(1, s.end.timeIntervalSince(s.start))
            let left = max(0, s.end.timeIntervalSince(tl.date))
            VStack(spacing: 10) {
                BuddyView(kind: id.kind, mood: .reading)
                    .frame(width: 96, height: 119)
                Text(SessionCopy.title(id))
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(Night.accent(id))
                if let phase = SessionCopy.breath(id, style: e.data.prefs.meditation.style, elapsed: tl.date.timeIntervalSince(s.start)) {
                    Text(phase)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(Night.accent(id))
                }
                Text(Fmt.clock(left))
                    .font(.system(size: 54, weight: .medium, design: .rounded))
                    .monospacedDigit()
                ProgressBar(value: 1 - left / total, tint: Night.accent(id), height: 8, track: Night.border)
                Text(SessionCopy.body(id))
                    .font(.system(size: 13))
                    .foregroundStyle(Night.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Stop early (won't count)") { e.stopSession(id) }
                    .buttonStyle(PillButton(kind: .ghost))
            }
            .padding(24)
            .frame(width: 340)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Night.card))
            .shadow(color: Color.black.opacity(0.3), radius: 24, x: 0, y: 12)
            .padding(30)
            .foregroundStyle(Night.text)
            .environment(\.colorScheme, .dark)
        }
    }
}
