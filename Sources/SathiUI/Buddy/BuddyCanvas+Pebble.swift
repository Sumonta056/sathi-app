import SwiftUI

extension BuddyCanvas {
    func drawPebble(_ ctx: inout GraphicsContext) {
        let body = Path(ellipseIn: CGRect(x: 10, y: 34, width: 80, height: 82))
        ctx.fill(body, with: .color(Palette.calmPale))
        var inner = ctx
        inner.clip(to: body)
        inner.fill(Path(ellipseIn: CGRect(x: 10, y: 52, width: 80, height: 70)), with: .color(Palette.calm))
        ctx.stroke(body, with: .color(Palette.calmDeep), lineWidth: 3.2)
        ctx.fill(Path(ellipseIn: CGRect(x: 24, y: 48, width: 9, height: 16)), with: .color(Color.white.opacity(0.7)))
        var stem = Path()
        stem.move(to: CGPoint(x: 50, y: 35))
        stem.addLine(to: CGPoint(x: 50, y: 26))
        ctx.stroke(stem, with: .color(Palette.leafLine), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        var leaf = Path()
        leaf.move(to: CGPoint(x: 50, y: 27))
        leaf.addQuadCurve(to: CGPoint(x: 68, y: 14), control: CGPoint(x: 54, y: 12))
        leaf.addQuadCurve(to: CGPoint(x: 50, y: 27), control: CGPoint(x: 66, y: 28))
        leaf.closeSubpath()
        ctx.fill(leaf, with: .color(Palette.leaf))
        ctx.stroke(leaf, with: .color(Palette.leafLine), lineWidth: 1.6)
    }
}
