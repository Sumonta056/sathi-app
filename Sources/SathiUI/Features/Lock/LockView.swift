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
                Palette.night.opacity(0.9).ignoresSafeArea()
                VStack(spacing: 14) {
                    Text(tl.date.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 80, weight: .medium, design: .rounded))
                        .monospacedDigit()
                    Text(tl.date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        .font(.system(size: 15))
                        .opacity(0.75)
                    BuddyView(kind: id.kind, mood: p >= 1 ? .cheer : (p > 0 ? .thirsty : .sad), level: p)
                        .frame(width: 150, height: 186)
                        .padding(.top, 8)
                    Text("SNOOZED TWICE · SCREEN PAUSED")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(Palette.waterMid)
                    Text(headline)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                    Text(instructions)
                        .font(.system(size: 16))
                        .foregroundStyle(Palette.lockBody)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 460)
                    LockHoldButton(progress: p, pressStart: $pressStart, done: $done) {
                        e.lockConfirmed(id)
                    }
                    Text(p >= 1 ? "Thank you." : (p > 0 ? "Keep holding…" : "Press and hold."))
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.lockHint)
                    LockSkipArea(id: id)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: 580)
                .padding(24)
            }
        }
    }

    private func progress(at date: Date) -> Double {
        if done { return 1 }
        return pressStart.map { min(1, date.timeIntervalSince($0) / Timing.lockHoldDuration) } ?? 0
    }

    private var headline: String {
        switch id {
        case .water: return "Fota is drying up. Go get some water."
        case .reading: return "Boi has waited long enough. Get your book."
        }
    }

    private var instructions: String {
        switch id {
        case .water: return "Take a few sips, then press and hold for 3 seconds. Your screen comes back right after."
        case .reading: return "Open your book, then press and hold for 3 seconds to start your reading timer."
        }
    }
}
