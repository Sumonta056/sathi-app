import SathiCore
import SwiftUI

struct SessionView: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        if let id = e.sessionHabit { content(id) }
    }

    private func content(_ id: HabitID) -> some View {
        TimelineView(.periodic(from: .now, by: UIMetrics.sessionRefresh)) { tl in
            let total = max(1, e.sessionEnd.timeIntervalSince(e.sessionStart))
            let left = max(0, e.sessionEnd.timeIntervalSince(tl.date))
            VStack(spacing: 10) {
                BuddyView(kind: id.kind, mood: .reading)
                    .frame(width: 96, height: 119)
                Text(SessionCopy.title(id))
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(Palette.deep(id))
                if let phase = SessionCopy.breath(id, style: e.data.prefs.meditation.style, elapsed: tl.date.timeIntervalSince(e.sessionStart)) {
                    Text(phase)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.calmDeep)
                }
                Text(Fmt.clock(left))
                    .font(.system(size: 54, weight: .medium, design: .rounded))
                    .monospacedDigit()
                ProgressBar(value: 1 - left / total, tint: Palette.accent(id), height: 8, track: Palette.deep(id).opacity(0.12))
                Text(SessionCopy.body(id))
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.ink2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                if e.queue.contains(.water) {
                    Text("Fota is waiting for you after this")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Palette.waterDeep)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Palette.water.opacity(0.14)))
                }
                Button("Stop early (won't count)") { e.stopSession() }
                    .buttonStyle(PillButton(kind: .ghost))
            }
            .padding(24)
            .frame(width: 340)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Palette.paper))
            .shadow(color: Color.black.opacity(0.3), radius: 24, x: 0, y: 12)
            .padding(30)
            .foregroundStyle(Palette.ink)
        }
    }
}
