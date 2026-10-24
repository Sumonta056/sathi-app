import SwiftUI

struct GlassIcon: View {
    var fill: Double
    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width / 40, size.height / 48)
            ctx.scaleBy(x: s, y: s)
            var g = Path()
            g.move(to: CGPoint(x: 6, y: 4))
            g.addLine(to: CGPoint(x: 34, y: 4))
            g.addLine(to: CGPoint(x: 30, y: 44))
            g.addLine(to: CGPoint(x: 10, y: 44))
            g.closeSubpath()
            ctx.fill(g, with: .color(Palette.waterGlass))
            var inner = ctx
            inner.clip(to: g)
            let top = 44 - CGFloat(fill) * 38
            inner.fill(Path(CGRect(x: 0, y: top, width: 40, height: 48)), with: .color(Palette.water))
            ctx.stroke(g, with: .color(Palette.outline), style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))
        }
    }
}
