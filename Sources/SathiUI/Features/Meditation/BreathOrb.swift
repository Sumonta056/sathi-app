import SathiCore
import SwiftUI

struct BreathOrb: View {
    let open: Double
    let t: Double
    let tint: BreathTint
    let ripples: [Double]

    private static let text = RGB(hex: NightHex.text)
    private static let sprout = RGB(hex: NightHex.sprout)

    var body: some View {
        let m = UIMetrics.self
        let orb = BreathMotion.scale(open: open, .orb)
        ZStack {
            rippleLayer(orb: orb)
            ForEach(0 ..< m.breathBlobs, id: \.self) { j in blob(j) }
            core
            StaticBuddy(habit: .meditation, size: m.breathFaceSize)
                .scaleEffect(BreathMotion.scale(open: open, .face))
        }
        .frame(width: m.breathStage, height: m.breathStage)
        .drawingGroup()
        .accessibilityHidden(true)
    }

    private func colour(_ j: Int) -> RGB {
        switch j {
        case 0: tint.main
        case 1: tint.accent.mix(tint.main, UIMetrics.breathBlobAccentMix)
        default: Self.sprout.mix(tint.main, UIMetrics.breathBlobSproutMix)
        }
    }

    private func blob(_ j: Int) -> some View {
        let m = UIMetrics.self
        let b = BreathMotion.blob(index: j, t: t, open: open)
        let c = colour(j)
        let fill = RadialGradient(
            stops: [
                .init(color: c.color(opacity: m.breathBlobOpacity), location: 0),
                .init(color: c.color(opacity: 0), location: m.breathBlobStop)
            ],
            center: m.breathBlobCenter,
            startRadius: 0,
            endRadius: m.breathBlob * m.breathBlobReach
        )
        return BlobShape(radii: b.radii)
            .fill(fill)
            .frame(width: m.breathBlob, height: m.breathBlob)
            .scaleEffect(b.scale)
            .rotationEffect(.degrees(b.rotation))
            .offset(x: b.dx, y: b.dy)
            .blur(radius: m.breathBlobBlur)
            .blendMode(.screen)
    }

    private var core: some View {
        let m = UIMetrics.self
        let fill = RadialGradient(
            stops: [
                .init(color: tint.main.mix(Self.text, m.breathCoreLight).color(opacity: m.breathCoreLightOpacity), location: 0),
                .init(color: tint.main.color(opacity: m.breathCoreMidOpacity), location: m.breathCoreMidStop),
                .init(color: tint.main.color(opacity: 0), location: 1)
            ],
            center: m.breathCoreCenter,
            startRadius: 0,
            endRadius: m.breathCore * m.breathCoreReach
        )
        return Circle()
            .fill(fill)
            .frame(width: m.breathCore, height: m.breathCore)
            .scaleEffect(BreathMotion.scale(open: open, .core))
    }

    private func rippleLayer(orb: Double) -> some View {
        let m = UIMetrics.self
        let colour = tint.accent.mix(Self.text, m.breathRippleLight).color()
        let from = m.breathRippleFrom * orb
        return ZStack {
            ForEach(Array(ripples.enumerated()), id: \.offset) { _, p in
                let r = from + (m.breathRippleTo - from) * p
                Circle()
                    .stroke(colour, lineWidth: m.breathRippleWidth)
                    .frame(width: r * 2, height: r * 2)
                    .opacity(m.breathRipplePeak * sin(.pi * p) * (1 - p * m.breathRippleFade))
            }
        }
        .blur(radius: m.breathRippleBlur)
    }
}
