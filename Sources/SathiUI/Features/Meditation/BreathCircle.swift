import SathiCore
import SwiftUI

struct BreathCircle: View {
    let style: BreathingStyle
    let start: Date

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    static func scale(for phase: BreathPhase) -> CGFloat {
        switch phase {
        case .inhale, .hold: UIMetrics.breathScaleBig
        case .exhale, .rest: UIMetrics.breathScaleSmall
        }
    }

    static func openness(_ style: BreathingStyle, elapsed: TimeInterval) -> Double {
        let step = BreathingPattern.step(style, at: elapsed)
        let length = BreathingPattern.steps(style).first { $0.0 == step.phase }?.1 ?? 0
        let p = length > 0 ? min(1, max(0, 1 - step.remaining / length)) : 1
        let eased = (1 - cos(.pi * p)) / 2
        switch step.phase {
        case .inhale: return eased
        case .hold: return 1
        case .exhale: return 1 - eased
        case .rest: return 0
        }
    }

    static func scale(_ style: BreathingStyle, elapsed: TimeInterval) -> CGFloat {
        let small = UIMetrics.breathScaleSmall
        return small + (UIMetrics.breathScaleBig - small) * CGFloat(openness(style, elapsed: elapsed))
    }

    static func haloOpacity(_ style: BreathingStyle, elapsed: TimeInterval) -> Double {
        let small = UIMetrics.breathHaloSmall
        return small + (UIMetrics.breathHaloBig - small) * openness(style, elapsed: elapsed)
    }

    var body: some View {
        let size = UIMetrics.breathCircleSize
        ZStack {
            TimelineView(.animation(minimumInterval: UIMetrics.animationFrameInterval, paused: !isVisible || reduceMotion)) { tl in
                let elapsed = max(0, tl.date.timeIntervalSince(start))
                glow(
                    scale: reduceMotion ? UIMetrics.breathScaleBig : Self.scale(style, elapsed: elapsed),
                    halo: reduceMotion ? UIMetrics.breathHaloBig : Self.haloOpacity(style, elapsed: elapsed)
                )
            }
            StaticBuddy(habit: .meditation, size: UIMetrics.breathFaceSize)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }

    private func glow(scale: CGFloat, halo: Double) -> some View {
        let size = UIMetrics.breathCircleSize
        return ZStack {
            Circle()
                .fill(Night.calm.opacity(halo))
                .frame(width: size * UIMetrics.breathHaloRatio, height: size * UIMetrics.breathHaloRatio)
            Circle()
                .fill(Night.calm.opacity(UIMetrics.breathGlowOpacity))
                .frame(width: size * UIMetrics.breathGlowRatio, height: size * UIMetrics.breathGlowRatio)
        }
        .scaleEffect(scale)
    }
}
