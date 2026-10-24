import SathiCore
import SwiftUI

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
