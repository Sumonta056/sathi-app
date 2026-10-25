import SwiftUI

extension BuddyCanvas {
    var faceInk: Color {
        switch kind {
        case .pebble: Night.calmGround
        case .drop, .book: BuddyInk.line
        }
    }

    var cheekFill: Color? {
        switch kind {
        case .pebble: Night.cheek.opacity(UIMetrics.pebbleCheekOpacity)
        case .drop, .book: mood == .happy || mood == .cheer ? BuddyInk.cheek.opacity(0.8) : nil
        }
    }

    func drawPebble(_ ctx: inout GraphicsContext) {
        ctx.fill(Path(ellipseIn: CGRect(x: 4, y: 32, width: 92, height: 92)), with: .color(Night.calm.opacity(UIMetrics.calmHaloOpacity)))
        let body = Path(ellipseIn: CGRect(x: 12, y: 40, width: 76, height: 76))
        ctx.fill(body, with: .color(Night.calm))
        ctx.fill(Path(ellipseIn: CGRect(x: 26, y: 50, width: 10, height: 14)), with: .color(Color.white.opacity(0.35)))
        var stem = Path()
        stem.move(to: CGPoint(x: 50, y: 41))
        stem.addLine(to: CGPoint(x: 50, y: 28))
        ctx.stroke(stem, with: .color(Night.sprout), style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
        ctx.fill(leaf(from: CGPoint(x: 50, y: 30), tip: CGPoint(x: 67, y: 15)), with: .color(Night.sprout))
        ctx.fill(leaf(from: CGPoint(x: 50, y: 33), tip: CGPoint(x: 36, y: 22)), with: .color(Night.sproutLight))
    }

    private func leaf(from base: CGPoint, tip: CGPoint) -> Path {
        let dx = tip.x - base.x
        let dy = tip.y - base.y
        var p = Path()
        p.move(to: base)
        p.addQuadCurve(to: tip, control: CGPoint(x: base.x + dx * 0.2, y: tip.y - dy * 0.1))
        p.addQuadCurve(to: base, control: CGPoint(x: tip.x - dx * 0.1, y: base.y + dy * 0.05))
        p.closeSubpath()
        return p
    }
}
