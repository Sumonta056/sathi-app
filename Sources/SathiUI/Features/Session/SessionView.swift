import SathiCore
import SwiftUI

struct SessionView: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        TimelineView(.periodic(from: .now, by: UIMetrics.sessionRefresh)) { tl in
            let total = max(1, e.sessionEnd.timeIntervalSince(e.sessionStart))
            let left = max(0, e.sessionEnd.timeIntervalSince(tl.date))
            VStack(spacing: 10) {
                BuddyView(kind: .book, mood: .reading)
                    .frame(width: 96, height: 119)
                Text("READING · DO NOT DISTURB")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(Palette.bookDeep)
                Text(Fmt.clock(left))
                    .font(.system(size: 54, weight: .medium, design: .rounded))
                    .monospacedDigit()
                ProgressBar(value: 1 - left / total, tint: Palette.book, height: 8, track: Palette.bookDeep.opacity(0.12))
                Text("Boi is reading with you. Water reminders wait until the timer ends.")
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
