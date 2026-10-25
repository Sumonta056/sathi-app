import SathiCore
import SwiftUI

struct LockHoldButton: View {
    let progress: Double
    @Binding var pressStart: Date?
    @Binding var done: Bool
    let onConfirm: @MainActor () -> Void

    var body: some View {
        ZStack {
            Circle().fill(Night.text.opacity(pressStart != nil ? UIMetrics.lockHoldPressedFillOpacity : UIMetrics.lockHoldFillOpacity))
            Circle().stroke(Night.text.opacity(UIMetrics.lockHoldTrackOpacity), lineWidth: UIMetrics.lockHoldRing)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(Night.waterLine, style: StrokeStyle(lineWidth: UIMetrics.lockHoldRing, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(label)
                .font(.system(size: UIMetrics.fontLockHold, weight: .semibold, design: .rounded))
        }
        .frame(width: UIMetrics.lockHoldSize, height: UIMetrics.lockHoldSize)
        .scaleEffect(pressStart != nil ? UIMetrics.lockHoldPressedScale : 1)
        .contentShape(Circle())
        .onLongPressGesture(
            minimumDuration: Timing.lockHoldDuration,
            maximumDistance: UIMetrics.lockHoldDistance,
            pressing: { pressing in
                if !done { pressStart = pressing ? Date() : nil }
            },
            perform: confirm
        )
        .padding(.top, UIMetrics.lockHoldTop)
    }

    private var label: String {
        if progress >= 1 { return "Done" }
        if progress > 0 { return "\(Int(ceil((1 - progress) * Timing.lockHoldDuration)))" }
        return "Hold"
    }

    private func confirm() {
        done = true
        pressStart = nil
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(Timing.lockConfirmDelay * 1_000_000_000))
            onConfirm()
        }
    }
}
