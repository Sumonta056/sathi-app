import SwiftUI

enum BuddyKind { case drop, book }
enum Mood { case happy, thirsty, sad, cheer, reading }

extension HabitID {
    var kind: BuddyKind { self == .water ? .drop : .book }
}

/// All buddy drawing happens in a 100 x 124 coordinate space.
enum BuddyPaths {
    static func drop() -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 50, y: 4))
        p.addCurve(to: CGPoint(x: 12, y: 76), control1: CGPoint(x: 40, y: 22), control2: CGPoint(x: 12, y: 50))
        p.addCurve(to: CGPoint(x: 50, y: 116), control1: CGPoint(x: 12, y: 99), control2: CGPoint(x: 29, y: 116))
        p.addCurve(to: CGPoint(x: 88, y: 76), control1: CGPoint(x: 71, y: 116), control2: CGPoint(x: 88, y: 99))
        p.addCurve(to: CGPoint(x: 50, y: 4), control1: CGPoint(x: 88, y: 50), control2: CGPoint(x: 60, y: 22))
        p.closeSubpath()
        return p
    }

    static func wave(top: CGFloat, phase: Double, amp: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: -10, y: 130))
        var x: CGFloat = -10
        while x <= 110 {
            let y = top + amp * CGFloat(sin(Double(x) / 25 * .pi + phase))
            p.addLine(to: CGPoint(x: x, y: y))
            x += 2
        }
        p.addLine(to: CGPoint(x: 110, y: 130))
        p.closeSubpath()
        return p
    }

    static func quad(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint) -> Path {
        var p = Path()
        p.move(to: a)
        p.addQuadCurve(to: b, control: c)
        return p
    }

    static func mouth(_ m: Mood) -> Path {
        switch m {
        case .happy:
            return quad(CGPoint(x: 40, y: 89), CGPoint(x: 50, y: 99), CGPoint(x: 60, y: 89))
        case .thirsty:
            var p = Path()
            p.move(to: CGPoint(x: 41, y: 94))
            p.addQuadCurve(to: CGPoint(x: 50, y: 94), control: CGPoint(x: 45.5, y: 90))
            p.addQuadCurve(to: CGPoint(x: 59, y: 94), control: CGPoint(x: 54.5, y: 98))
            return p
        case .sad:
            return quad(CGPoint(x: 39, y: 98), CGPoint(x: 50, y: 86), CGPoint(x: 61, y: 98))
        case .cheer:
            var p = quad(CGPoint(x: 37, y: 86), CGPoint(x: 50, y: 106), CGPoint(x: 63, y: 86))
            p.closeSubpath()
            return p
        case .reading:
            return quad(CGPoint(x: 43, y: 91), CGPoint(x: 50, y: 96), CGPoint(x: 57, y: 91))
        }
    }

    static func drip(_ c: CGPoint) -> Path {
        var p = Path(ellipseIn: CGRect(x: c.x - 4.5, y: c.y + 5, width: 9, height: 9))
        p.move(to: c)
        p.addLine(to: CGPoint(x: c.x - 4.2, y: c.y + 8.5))
        p.addLine(to: CGPoint(x: c.x + 4.2, y: c.y + 8.5))
        p.closeSubpath()
        return p
    }

    static func star(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
        let k = r * 0.28
        var p = Path()
        p.move(to: CGPoint(x: cx, y: cy - r))
        p.addLine(to: CGPoint(x: cx + k, y: cy - k))
        p.addLine(to: CGPoint(x: cx + r, y: cy))
        p.addLine(to: CGPoint(x: cx + k, y: cy + k))
        p.addLine(to: CGPoint(x: cx, y: cy + r))
        p.addLine(to: CGPoint(x: cx - k, y: cy + k))
        p.addLine(to: CGPoint(x: cx - r, y: cy))
        p.addLine(to: CGPoint(x: cx - k, y: cy - k))
        p.closeSubpath()
        return p
    }

    static func rr(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> Path {
        Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: r)
    }
}

/// An animated buddy: Fota (water drop) or Boi (book).
struct BuddyView: View {
    var kind: BuddyKind
    var mood: Mood
    var level: Double = 0.7

    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            BuddyCanvas(kind: kind, mood: mood, level: level, t: t)
                .scaleEffect(x: sx(t), y: sy(t), anchor: .bottom)
                .rotationEffect(.degrees(mood == .thirsty ? sin(t * 4.2) * 5 : 0), anchor: .bottom)
                .offset(y: dy(t))
        }
        .aspectRatio(100.0 / 124.0, contentMode: .fit)
    }

    private func dy(_ t: Double) -> CGFloat {
        switch mood {
        case .happy: return CGFloat(-1.5 + 1.5 * sin(t * 1.96))
        case .reading: return CGFloat(-1 + sin(t * 1.5))
        case .cheer: return CGFloat(-abs(sin(t * 4.2)) * 10)
        default: return 0
        }
    }
    private func sx(_ t: Double) -> CGFloat { mood == .sad ? CGFloat(1 + 0.03 * sin(t * 2.4)) : 1 }
    private func sy(_ t: Double) -> CGFloat { mood == .sad ? CGFloat(1 - 0.03 * sin(t * 2.4)) : 1 }
}

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
            if kind == .drop { drawDrop(&ctx) } else { drawBook(&ctx) }
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

        if mood == .cheer || mood == .reading {
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
            ctx.fill(g, with: .color(Color(hex: 0xEEF8FD)))
            var inner = ctx
            inner.clip(to: g)
            let top = 44 - CGFloat(fill) * 38
            inner.fill(Path(CGRect(x: 0, y: top, width: 40, height: 48)), with: .color(Palette.water))
            ctx.stroke(g, with: .color(Palette.outline), style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))
        }
    }
}

/// A sip bottle you drag to show how much water is left.
struct BottleView: View {
    let was: Double
    @Binding var now: Double

    private let top: CGFloat = 40
    private let bot: CGFloat = 154

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width / 80, geo.size.height / 164)
            Canvas { ctx, _ in
                ctx.scaleBy(x: s, y: s)
                let shape = BottleView.bodyPath()
                ctx.fill(Path(roundedRect: CGRect(x: 25, y: 5, width: 30, height: 17), cornerRadius: 4), with: .color(Palette.waterDeep))
                ctx.fill(shape, with: .color(Color(hex: 0xEEF8FD)))
                let yWas = y(was)
                let yNow = y(now)
                var inner = ctx
                inner.clip(to: shape)
                inner.fill(Path(CGRect(x: 0, y: yWas, width: 80, height: max(0, yNow - yWas))), with: .color(Color(hex: 0xBFE8FA)))
                inner.fill(Path(CGRect(x: 0, y: yNow, width: 80, height: 164 - yNow)), with: .color(Palette.water))
                ctx.stroke(shape, with: .color(Palette.outline), style: StrokeStyle(lineWidth: 2.6, lineJoin: .round))
                var ghost = Path()
                ghost.move(to: CGPoint(x: 8, y: yWas))
                ghost.addLine(to: CGPoint(x: 72, y: yWas))
                ctx.stroke(ghost, with: .color(Palette.outline.opacity(0.6)), style: StrokeStyle(lineWidth: 1.6, dash: [4, 3]))
                let handle = Path(roundedRect: CGRect(x: -2, y: yNow - 7, width: 84, height: 14), cornerRadius: 7)
                ctx.fill(handle, with: .color(.white))
                ctx.stroke(handle, with: .color(Palette.outline), lineWidth: 2)
                var grip = Path()
                grip.move(to: CGPoint(x: 33, y: yNow - 2)); grip.addLine(to: CGPoint(x: 47, y: yNow - 2))
                grip.move(to: CGPoint(x: 33, y: yNow + 2)); grip.addLine(to: CGPoint(x: 47, y: yNow + 2))
                ctx.stroke(grip, with: .color(Palette.outline), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
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
