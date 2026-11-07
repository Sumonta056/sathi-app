import SwiftUI

struct BreathRing: View {
    let progress: Double
    let tint: BreathTint

    var body: some View {
        let m = UIMetrics.self
        let d = m.breathRingRadius * 2
        let arc = tint.main.mix(RGB(hex: NightHex.text), m.breathRingLight).color(opacity: m.breathArcOpacity)
        ZStack {
            Circle()
                .stroke(Night.border.opacity(m.breathTrackOpacity), lineWidth: m.breathRingWidth)
                .frame(width: d, height: d)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(arc, style: StrokeStyle(lineWidth: m.breathRingWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: d, height: d)
            ticks.stroke(Night.border, lineWidth: m.breathRingWidth)
            Circle()
                .fill(Night.text)
                .frame(width: m.breathDotRadius * 2, height: m.breathDotRadius * 2)
                .offset(dot)
        }
        .frame(width: m.breathStage, height: m.breathStage)
        .accessibilityHidden(true)
    }

    private static func angle(_ fraction: Double) -> Double {
        -Double.pi / 2 + 2 * Double.pi * fraction
    }

    private var dot: CGSize {
        let a = Self.angle(progress)
        let r = UIMetrics.breathRingRadius
        return CGSize(width: r * cos(a), height: r * sin(a))
    }

    private var ticks: Path {
        let m = UIMetrics.self
        let c = m.breathStage / 2
        var p = Path()
        for i in 0 ..< m.breathTicks {
            let a = Self.angle(Double(i) / Double(m.breathTicks))
            p.move(to: CGPoint(x: c + m.breathTickInner * cos(a), y: c + m.breathTickInner * sin(a)))
            p.addLine(to: CGPoint(x: c + m.breathTickOuter * cos(a), y: c + m.breathTickOuter * sin(a)))
        }
        return p
    }
}
