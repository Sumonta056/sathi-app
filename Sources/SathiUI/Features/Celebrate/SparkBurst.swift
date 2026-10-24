import SwiftUI

struct SparkBurst: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    private let turn: Double = 360

    static func phase(at t: TimeInterval) -> (scale: CGFloat, opacity: Double) {
        let d = UIMetrics.sparkDuration
        let p = (t.truncatingRemainder(dividingBy: d) + d).truncatingRemainder(dividingBy: d) / d
        let peak = UIMetrics.sparkPeak
        let opacity = p < peak ? p / peak : (1 - p) / (1 - peak)
        let scale = UIMetrics.sparkStartScale + (UIMetrics.sparkEndScale - UIMetrics.sparkStartScale) * CGFloat(p)
        return (scale, opacity)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: UIMetrics.animationFrameInterval, paused: !isVisible || reduceMotion)) { tl in
            let p = reduceMotion ? (scale: 1, opacity: 1) : Self.phase(at: tl.date.timeIntervalSinceReferenceDate)
            rays
                .scaleEffect(p.scale)
                .opacity(p.opacity)
        }
        .frame(width: UIMetrics.sparkSize, height: UIMetrics.sparkSize)
        .accessibilityHidden(true)
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }

    private var rays: some View {
        ZStack {
            ForEach(0 ..< UIMetrics.sparkRays, id: \.self) { i in
                Capsule()
                    .fill(Night.spark)
                    .frame(width: UIMetrics.sparkRayWidth, height: UIMetrics.sparkRayLength)
                    .offset(y: (UIMetrics.sparkRayLength - UIMetrics.sparkSize) / 2)
                    .rotationEffect(.degrees(turn / Double(UIMetrics.sparkRays) * Double(i)))
            }
        }
        .frame(width: UIMetrics.sparkSize, height: UIMetrics.sparkSize)
    }
}
