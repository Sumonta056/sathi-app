import SathiCore
import SwiftUI

struct LockView: View {
    @EnvironmentObject var e: Engine
    let id: HabitID

    @State private var pressStart: Date?
    @State private var done = false

    var body: some View {
        TimelineView(.animation(minimumInterval: UIMetrics.animationFrameInterval)) { tl in
            let p = progress(at: tl.date)
            ZStack {
                Night.sidebar.opacity(UIMetrics.lockBackdropOpacity).ignoresSafeArea()
                VStack(spacing: UIMetrics.lockSpacing) {
                    Text(tl.date.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: UIMetrics.fontLockClock, weight: .medium, design: .rounded))
                        .monospacedDigit()
                    Text(tl.date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        .font(.system(size: UIMetrics.fontLockDate))
                        .opacity(UIMetrics.lockDateOpacity)
                    BuddyView(kind: id.kind, mood: p >= 1 ? .cheer : (p > 0 ? .thirsty : .sad), level: p)
                        .frame(width: UIMetrics.lockBuddySize.width, height: UIMetrics.lockBuddySize.height)
                        .padding(.top, UIMetrics.lockBuddyTop)
                    Text("SNOOZED TWICE · SCREEN PAUSED")
                        .font(.system(size: UIMetrics.fontLockReason, weight: .semibold))
                        .tracking(UIMetrics.lockReasonTracking)
                        .foregroundStyle(Night.waterLine)
                    Text(headline)
                        .font(.system(size: UIMetrics.fontLockHeadline, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                    Text(instructions)
                        .font(.system(size: UIMetrics.fontLockBody))
                        .foregroundStyle(Night.chipText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: UIMetrics.lockTextMaxWidth)
                    LockHoldButton(progress: p, pressStart: $pressStart, done: $done) {
                        e.lockConfirmed(id)
                    }
                    Text(p >= 1 ? "Thank you." : (p > 0 ? "Keep holding…" : "Press and hold."))
                        .font(.system(size: UIMetrics.fontLockHint))
                        .foregroundStyle(Night.muted)
                    LockSkipArea(id: id)
                }
                .foregroundStyle(Night.text)
                .frame(maxWidth: UIMetrics.lockMaxWidth)
                .padding(UIMetrics.lockPadding)
            }
        }
        .environment(\.colorScheme, .dark)
    }

    private func progress(at date: Date) -> Double {
        if done { return 1 }
        return pressStart.map { min(1, date.timeIntervalSince($0) / Timing.lockHoldDuration) } ?? 0
    }

    private var headline: String {
        switch id {
        case .water: return "Fota is drying up. Go get some water."
        case .reading: return "Boi has waited long enough. Get your book."
        case .meditation: return "Shanti is waiting. Take a slow breath."
        }
    }

    private var instructions: String {
        switch id {
        case .water: return "Take a few sips, then press and hold for 3 seconds. Your screen comes back right after."
        case .reading: return "Open your book, then press and hold for 3 seconds to start your reading timer."
        case .meditation: return "Sit back, then press and hold for 3 seconds to start your breathing session."
        }
    }
}
