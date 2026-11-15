import CoreGraphics

enum PromptFit {
    static func maxHeight(screen: CGRect, margin: CGFloat) -> CGFloat {
        screen.height - 2 * margin
    }

    static func clamped(origin: CGPoint, size: CGSize, screen: CGRect, margin: CGFloat) -> CGPoint {
        let area = screen.insetBy(dx: margin, dy: margin)
        let x = size.width > area.width ? area.minX : min(max(origin.x, area.minX), area.maxX - size.width)
        let y = size.height > area.height ? area.maxY - size.height : min(max(origin.y, area.minY), area.maxY - size.height)
        return CGPoint(x: x, y: y)
    }
}
