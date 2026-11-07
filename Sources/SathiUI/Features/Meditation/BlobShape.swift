import SwiftUI

struct BlobShape: Shape {
    var radii: [Double]

    private static let k: CGFloat = 0.5523

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let top = w * value(0)
        let bottom = w * (1 - value(1))
        let left = h * value(2)
        let right = h * value(3)
        let k = Self.k
        let o = rect.origin
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: o.x + x, y: o.y + y) }
        var p = Path()
        p.move(to: pt(top, 0))
        p.addCurve(to: pt(w, right), control1: pt(top + k * (w - top), 0), control2: pt(w, right - k * right))
        p.addCurve(to: pt(bottom, h), control1: pt(w, right + k * (h - right)), control2: pt(bottom + k * (w - bottom), h))
        p.addCurve(to: pt(0, left), control1: pt(bottom - k * bottom, h), control2: pt(0, left + k * (h - left)))
        p.addCurve(to: pt(top, 0), control1: pt(0, left - k * left), control2: pt(top - k * top, 0))
        p.closeSubpath()
        return p
    }

    private func value(_ i: Int) -> CGFloat {
        i < radii.count ? CGFloat(radii[i]) : 0.5
    }
}
