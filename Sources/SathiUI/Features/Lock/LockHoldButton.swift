import SathiCore
import SwiftUI

struct LockHoldButton: View {
    let progress: Double
    @Binding var pressStart: Date?
    @Binding var done: Bool
    let onConfirm: @MainActor () -> Void

    var body: some View {
        ZStack {
            Circle().fill(Color.white.opacity(pressStart != nil ? 0.22 : 0.12))
            Circle().stroke(Color.white.opacity(0.18), lineWidth: 8)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(Palette.waterMid, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(label)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
        }
        .frame(width: 136, height: 136)
        .scaleEffect(pressStart != nil ? 0.95 : 1)
        .contentShape(Circle())
        .onLongPressGesture(
            minimumDuration: Timing.lockHoldDuration,
            maximumDistance: UIMetrics.lockHoldDistance,
            pressing: { pressing in
                if !done { pressStart = pressing ? Date() : nil }
            },
            perform: confirm
        )
        .padding(.top, 6)
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
