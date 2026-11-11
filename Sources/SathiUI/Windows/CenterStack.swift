import CoreGraphics

enum CenterStack {
    static func noteOrigin(note: CGSize, prompt: CGRect?, screen: CGRect, gap: CGFloat) -> CGPoint {
        let center = CGPoint(x: screen.midX - note.width / 2, y: screen.midY - note.height / 2)
        guard let prompt else { return center }
        let x = prompt.midX - note.width / 2
        let above = prompt.maxY + gap
        if above + note.height <= screen.maxY { return CGPoint(x: x, y: above) }
        let below = prompt.minY - gap - note.height
        if below >= screen.minY { return CGPoint(x: x, y: below) }
        return center
    }

    static func mouseScreenFrame(screens: [CGRect], mouse: CGPoint) -> CGRect {
        screens.first { $0.contains(mouse) } ?? screens.first ?? .zero
    }
}
