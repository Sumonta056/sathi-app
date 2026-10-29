import SathiCore
import SwiftUI

struct QuickLockView: View {
    @EnvironmentObject var e: Engine
    let id: UUID

    @State private var pressStart: Date?
    @State private var done = false

    static func confirm(_ id: UUID, engine: Engine) {
        engine.quickDone(id)
    }

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
                    Image(systemName: "bell")
                        .font(.system(size: UIMetrics.quickLockIcon, weight: .semibold))
                        .foregroundStyle(Night.quick)
                        .padding(.top, UIMetrics.lockBuddyTop)
                    if let item = e.quick(id) { texts(item) }
                    LockHoldButton(progress: p, pressStart: $pressStart, done: $done) {
                        Self.confirm(id, engine: e)
                    }
                    Text(hint(p))
                        .font(.system(size: UIMetrics.fontLockHint))
                        .foregroundStyle(Night.muted)
                    Button { e.removeQuick(id) } label: {
                        Text("Delete this reminder")
                            .underline()
                            .font(.system(size: UIMetrics.fontLockHint))
                            .foregroundStyle(Night.muted)
                    }
                    .buttonStyle(.plain)
                    .padding(UIMetrics.lockSkipLinkPadding)
                }
                .foregroundStyle(Night.text)
                .frame(maxWidth: UIMetrics.lockMaxWidth)
                .padding(UIMetrics.lockPadding)
            }
        }
        .environment(\.colorScheme, .dark)
    }

    private func texts(_ item: QuickReminder) -> some View {
        VStack(spacing: UIMetrics.lockSpacing) {
            Text(verbatim: Copywriter.quickEyebrow(due: item.due, calendar: Calendar.gregorian(in: e.timeZone)))
                .font(.system(size: UIMetrics.fontLockReason, weight: .semibold))
                .tracking(UIMetrics.lockReasonTracking)
                .foregroundStyle(Night.quick)
            Text(verbatim: item.text)
                .font(.system(size: UIMetrics.fontLockHeadline, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
            Text("Press and hold for 3 seconds to mark it done. Your screen comes back right after.")
                .font(.system(size: UIMetrics.fontLockBody))
                .foregroundStyle(Night.chipText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: UIMetrics.lockTextMaxWidth)
        }
    }

    private func hint(_ p: Double) -> String {
        p >= 1 ? "Thank you." : (p > 0 ? "Keep holding…" : "Hold for Done")
    }

    private func progress(at date: Date) -> Double {
        if done { return 1 }
        return pressStart.map { min(1, date.timeIntervalSince($0) / Timing.lockHoldDuration) } ?? 0
    }
}
