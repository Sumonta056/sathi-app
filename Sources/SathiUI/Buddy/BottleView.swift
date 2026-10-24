import SwiftUI

struct BottleView: View {
    let was: Double
    @Binding var now: Double
    var ink: WaterInk = .day

    private let top: CGFloat = 40
    private let bot: CGFloat = 154

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width / 80, geo.size.height / 164)
            Canvas { ctx, _ in
                ctx.scaleBy(x: s, y: s)
                let shape = BottleView.bodyPath()
                ctx.fill(Path(roundedRect: CGRect(x: 25, y: 5, width: 30, height: 17), cornerRadius: 4), with: .color(ink.cap))
                ctx.fill(shape, with: .color(ink.glass))
                let yWas = y(was)
                let yNow = y(now)
                var inner = ctx
                inner.clip(to: shape)
                inner.fill(Path(CGRect(x: 0, y: yWas, width: 80, height: max(0, yNow - yWas))), with: .color(ink.drained))
                inner.fill(Path(CGRect(x: 0, y: yNow, width: 80, height: 164 - yNow)), with: .color(ink.water))
                ctx.stroke(shape, with: .color(ink.outline), style: StrokeStyle(lineWidth: 2.6, lineJoin: .round))
                var ghost = Path()
                ghost.move(to: CGPoint(x: 8, y: yWas))
                ghost.addLine(to: CGPoint(x: 72, y: yWas))
                ctx.stroke(ghost, with: .color(ink.outline.opacity(0.6)), style: StrokeStyle(lineWidth: 1.6, dash: [4, 3]))
                let handle = Path(roundedRect: CGRect(x: -2, y: yNow - 7, width: 84, height: 14), cornerRadius: 7)
                ctx.fill(handle, with: .color(.white))
                ctx.stroke(handle, with: .color(ink.outline), lineWidth: 2)
                var grip = Path()
                grip.move(to: CGPoint(x: 33, y: yNow - 2)); grip.addLine(to: CGPoint(x: 47, y: yNow - 2))
                grip.move(to: CGPoint(x: 33, y: yNow + 2)); grip.addLine(to: CGPoint(x: 47, y: yNow + 2))
                ctx.stroke(grip, with: .color(ink.outline), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { v in
                    let yy = v.location.y / s
                    now = min(was, max(0, Double((bot - yy) / (bot - top))))
                }
            )
        }
        .help("Drag to where your water is now")
    }

    private func y(_ l: Double) -> CGFloat { bot - CGFloat(l) * (bot - top) }

    static func bodyPath() -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 27, y: 22))
        p.addLine(to: CGPoint(x: 53, y: 22))
        p.addLine(to: CGPoint(x: 53, y: 29))
        p.addCurve(to: CGPoint(x: 68, y: 48), control1: CGPoint(x: 53, y: 34), control2: CGPoint(x: 68, y: 36))
        p.addLine(to: CGPoint(x: 68, y: 142))
        p.addQuadCurve(to: CGPoint(x: 56, y: 154), control: CGPoint(x: 68, y: 154))
        p.addLine(to: CGPoint(x: 24, y: 154))
        p.addQuadCurve(to: CGPoint(x: 12, y: 142), control: CGPoint(x: 12, y: 154))
        p.addLine(to: CGPoint(x: 12, y: 48))
        p.addCurve(to: CGPoint(x: 27, y: 29), control1: CGPoint(x: 12, y: 36), control2: CGPoint(x: 27, y: 34))
        p.closeSubpath()
        return p
    }
}
