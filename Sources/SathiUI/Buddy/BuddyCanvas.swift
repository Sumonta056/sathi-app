import SathiCore
import SwiftUI

struct BuddyCanvas: View {
    let kind: BuddyKind
    let mood: Mood
    let level: Double
    let t: Double

    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width / 100, size.height / 124)
            ctx.translateBy(x: (size.width - 100 * s) / 2, y: (size.height - 124 * s) / 2)
            ctx.scaleBy(x: s, y: s)
            switch kind {
            case .drop: drawDrop(&ctx)
            case .book: drawBook(&ctx)
            case .pebble: drawPebble(&ctx)
            }
            drawFace(&ctx)
        }
    }

    private func drawDrop(_ ctx: inout GraphicsContext) {
        let drop = BuddyPaths.drop()
        ctx.fill(drop, with: .color(Palette.waterPale))
        var inner = ctx
        inner.clip(to: drop)
        let top = CGFloat(116 - max(0, min(1, level)) * 110)
        inner.fill(BuddyPaths.wave(top: top, phase: t * 2.6, amp: 3), with: .color(Palette.waterMid))
        inner.fill(BuddyPaths.wave(top: top + 3, phase: -t * 1.7, amp: 3), with: .color(Palette.water))
        ctx.stroke(drop, with: .color(Palette.outline), style: StrokeStyle(lineWidth: 3.2, lineJoin: .round))
        ctx.fill(Path(ellipseIn: CGRect(x: 25.5, y: 52, width: 9, height: 20)), with: .color(Color.white.opacity(0.75)))
    }

    private func drawBook(_ ctx: inout GraphicsContext) {
        let line = Palette.bookLine
        let pages = BuddyPaths.rr(22, 30, 66, 88, 8)
        ctx.fill(pages, with: .color(Palette.pages))
        ctx.stroke(pages, with: .color(line), lineWidth: 2.6)
        let cover = BuddyPaths.rr(12, 24, 72, 90, 9)
        ctx.fill(cover, with: .color(Palette.cover))
        ctx.stroke(cover, with: .color(line), lineWidth: 3.2)
        let spine = BuddyPaths.rr(12, 24, 14, 90, 7)
        ctx.fill(spine, with: .color(Palette.spine))
        ctx.stroke(spine, with: .color(line), lineWidth: 3.2)
        ctx.fill(BuddyPaths.rr(36, 36, 34, 6, 3), with: .color(Color.white.opacity(0.55)))
        var rib = Path()
        rib.move(to: CGPoint(x: 62, y: 20))
        rib.addLine(to: CGPoint(x: 62, y: 46))
        rib.addLine(to: CGPoint(x: 67, y: 41))
        rib.addLine(to: CGPoint(x: 72, y: 46))
        rib.addLine(to: CGPoint(x: 72, y: 20))
        rib.closeSubpath()
        ctx.fill(rib, with: .color(Palette.ribbon))
        ctx.stroke(rib, with: .color(line), lineWidth: 1.6)
    }

    private func drawFace(_ ctx: inout GraphicsContext) {
        let ink = Palette.ink
        let round = StrokeStyle(lineWidth: 3.4, lineCap: .round, lineJoin: .round)

        if kind == .pebble || mood == .cheer || mood == .reading {
            ctx.stroke(BuddyPaths.quad(CGPoint(x: 32, y: 79), CGPoint(x: 38, y: 70), CGPoint(x: 44, y: 79)), with: .color(ink), style: round)
            ctx.stroke(BuddyPaths.quad(CGPoint(x: 56, y: 79), CGPoint(x: 62, y: 70), CGPoint(x: 68, y: 79)), with: .color(ink), style: round)
        } else {
            let ph = t.truncatingRemainder(dividingBy: 5)
            let b: CGFloat = (ph > 4.72 && ph < 4.86) ? 0.12 : 1
            for x in [CGFloat(38), CGFloat(62)] {
                ctx.fill(Path(ellipseIn: CGRect(x: x - 5.3, y: 77 - 5.3 * b, width: 10.6, height: 10.6 * b)), with: .color(ink))
                if b == 1 {
                    ctx.fill(Path(ellipseIn: CGRect(x: x + 0.2, y: 73.2, width: 3.6, height: 3.6)), with: .color(.white))
                }
            }
        }

        if mood == .sad {
            ctx.stroke(BuddyPaths.quad(CGPoint(x: 30, y: 66), CGPoint(x: 36, y: 68), CGPoint(x: 42, y: 70.5)), with: .color(ink), style: round)
            ctx.stroke(BuddyPaths.quad(CGPoint(x: 70, y: 66), CGPoint(x: 64, y: 68), CGPoint(x: 58, y: 70.5)), with: .color(ink), style: round)
        }

        if mood == .happy || mood == .cheer {
            for x in [CGFloat(27), CGFloat(73)] {
                ctx.fill(Path(ellipseIn: CGRect(x: x - 5.5, y: 83.5, width: 11, height: 11)), with: .color(Palette.cheek.opacity(0.8)))
            }
        }

        let mouth = BuddyPaths.mouth(mood)
        if mood == .cheer { ctx.fill(mouth, with: .color(ink)) }
        ctx.stroke(mouth, with: .color(ink), style: round)

        if mood == .thirsty {
            let k = t.truncatingRemainder(dividingBy: 2) / 2
            var c = ctx
            c.opacity = k < 0.2 ? k / 0.2 : 1 - (k - 0.2) / 0.8
            c.fill(BuddyPaths.drip(CGPoint(x: 82 + 2 * k, y: 40 + 18 * k)), with: .color(Palette.drip))
        }
        if mood == .sad {
            let k = t.truncatingRemainder(dividingBy: 1.5) / 1.5
            var c = ctx
            c.opacity = k < 0.15 ? k / 0.15 : 1 - (k - 0.15) / 0.85
            c.fill(BuddyPaths.drip(CGPoint(x: 65, y: 82 + 36 * k)), with: .color(Palette.drip))
        }
        if mood == .cheer {
            var c = ctx
            c.opacity = 0.65 + 0.35 * sin(t * 6)
            c.fill(BuddyPaths.star(90, 25, 9), with: .color(Palette.spark))
            c.fill(BuddyPaths.star(9, 36.5, 6.5), with: .color(Palette.spark))
            c.fill(BuddyPaths.star(84, 56, 4), with: .color(Palette.spark))
        }
    }
}
