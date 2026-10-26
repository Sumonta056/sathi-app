import SwiftUI

extension BuddyCanvas {
    func drawKettlebell(_ ctx: inout GraphicsContext) {
        let line = BuddyInk.kettleLine
        let handle = Path(ellipseIn: CGRect(x: 24, y: 8, width: 52, height: 60))
        ctx.stroke(handle, with: .color(line), style: StrokeStyle(lineWidth: 14))
        ctx.stroke(handle, with: .color(BuddyInk.kettle), style: StrokeStyle(lineWidth: 8))
        let body = BuddyPaths.rr(8, 40, 84, 78, 38)
        ctx.fill(body, with: .color(BuddyInk.kettle))
        var inner = ctx
        inner.clip(to: body)
        inner.fill(Path(ellipseIn: CGRect(x: -10, y: 104, width: 120, height: 30)), with: .color(BuddyInk.kettleDeep))
        ctx.stroke(body, with: .color(line), style: StrokeStyle(lineWidth: 3.2, lineJoin: .round))
        ctx.fill(Path(ellipseIn: CGRect(x: 22, y: 52, width: 9, height: 16)), with: .color(Color.white.opacity(0.6)))
    }
}
