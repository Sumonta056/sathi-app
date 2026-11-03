import SwiftUI

struct GitHubMark: Shape {
    private static let viewBox: CGFloat = 16

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / Self.viewBox
        return Self.mark.applying(CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: rect.minX / scale, y: rect.minY / scale))
    }

    private static let mark: Path = {
        var p = Path()
        p.move(to: CGPoint(x: 8, y: 0))
        p.addCurve(to: CGPoint(x: 0, y: 8), control1: CGPoint(x: 3.58, y: 0), control2: CGPoint(x: 0, y: 3.58))
        p.addCurve(to: CGPoint(x: 5.47, y: 15.59), control1: CGPoint(x: 0, y: 11.54), control2: CGPoint(x: 2.29, y: 14.53))
        p.addCurve(to: CGPoint(x: 6.02, y: 15.21), control1: CGPoint(x: 5.87, y: 15.66), control2: CGPoint(x: 6.02, y: 15.42))
        p.addCurve(to: CGPoint(x: 6.01, y: 13.72), control1: CGPoint(x: 6.02, y: 15.02), control2: CGPoint(x: 6.01, y: 14.39))
        p.addCurve(to: CGPoint(x: 3.32, y: 12.78), control1: CGPoint(x: 4, y: 14.09), control2: CGPoint(x: 3.48, y: 13.23))
        p.addCurve(to: CGPoint(x: 2.5, y: 11.65), control1: CGPoint(x: 3.23, y: 12.55), control2: CGPoint(x: 2.84, y: 11.84))
        p.addCurve(to: CGPoint(x: 2.49, y: 11.12), control1: CGPoint(x: 2.22, y: 11.5), control2: CGPoint(x: 1.82, y: 11.13))
        p.addCurve(to: CGPoint(x: 3.72, y: 11.94), control1: CGPoint(x: 3.12, y: 11.11), control2: CGPoint(x: 3.57, y: 11.7))
        p.addCurve(to: CGPoint(x: 6.05, y: 12.6), control1: CGPoint(x: 4.44, y: 13.15), control2: CGPoint(x: 5.59, y: 12.81))
        p.addCurve(to: CGPoint(x: 6.56, y: 11.53), control1: CGPoint(x: 6.12, y: 12.08), control2: CGPoint(x: 6.33, y: 11.73))
        p.addCurve(to: CGPoint(x: 2.92, y: 7.58), control1: CGPoint(x: 4.78, y: 11.33), control2: CGPoint(x: 2.92, y: 10.64))
        p.addCurve(to: CGPoint(x: 3.74, y: 5.43), control1: CGPoint(x: 2.92, y: 6.71), control2: CGPoint(x: 3.23, y: 5.99))
        p.addCurve(to: CGPoint(x: 3.82, y: 3.31), control1: CGPoint(x: 3.66, y: 5.23), control2: CGPoint(x: 3.38, y: 4.41))
        p.addCurve(to: CGPoint(x: 6.02, y: 4.13), control1: CGPoint(x: 3.82, y: 3.31), control2: CGPoint(x: 4.49, y: 3.1))
        p.addCurve(to: CGPoint(x: 8.02, y: 3.86), control1: CGPoint(x: 6.66, y: 3.95), control2: CGPoint(x: 7.34, y: 3.86))
        p.addCurve(to: CGPoint(x: 10.02, y: 4.13), control1: CGPoint(x: 8.7, y: 3.86), control2: CGPoint(x: 9.38, y: 3.95))
        p.addCurve(to: CGPoint(x: 12.22, y: 3.31), control1: CGPoint(x: 11.55, y: 3.09), control2: CGPoint(x: 12.22, y: 3.31))
        p.addCurve(to: CGPoint(x: 12.3, y: 5.43), control1: CGPoint(x: 12.66, y: 4.41), control2: CGPoint(x: 12.38, y: 5.23))
        p.addCurve(to: CGPoint(x: 13.12, y: 7.58), control1: CGPoint(x: 12.81, y: 5.99), control2: CGPoint(x: 13.12, y: 6.7))
        p.addCurve(to: CGPoint(x: 9.47, y: 11.53), control1: CGPoint(x: 13.12, y: 10.65), control2: CGPoint(x: 11.25, y: 11.33))
        p.addCurve(to: CGPoint(x: 10.01, y: 13.01), control1: CGPoint(x: 9.76, y: 11.78), control2: CGPoint(x: 10.01, y: 12.26))
        p.addCurve(to: CGPoint(x: 10, y: 15.21), control1: CGPoint(x: 10.01, y: 14.08), control2: CGPoint(x: 10, y: 14.94))
        p.addCurve(to: CGPoint(x: 10.55, y: 15.59), control1: CGPoint(x: 10, y: 15.42), control2: CGPoint(x: 10.15, y: 15.67))
        p.addCurve(to: CGPoint(x: 16, y: 8), control1: CGPoint(x: 13.81, y: 14.49), control2: CGPoint(x: 16, y: 11.44))
        p.addCurve(to: CGPoint(x: 8, y: 0), control1: CGPoint(x: 16, y: 3.58), control2: CGPoint(x: 12.42, y: 0))
        p.closeSubpath()
        return p
    }()
}
