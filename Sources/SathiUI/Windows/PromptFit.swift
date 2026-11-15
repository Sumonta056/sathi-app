import CoreGraphics

enum PromptFit {
    static func size(screen: CGRect, margin: CGFloat) -> CGSize {
        CGSize(
            width: min(UIMetrics.activityPromptWidth, screen.width - 2 * margin),
            height: min(UIMetrics.activityPromptHeight, screen.height - 2 * margin)
        )
    }

    static func scrolls(screen: CGRect, margin: CGFloat) -> Bool {
        screen.height < UIMetrics.activityPromptHeight + 2 * margin
    }

    static func overflows(content: CGFloat, space: CGFloat) -> Bool {
        space > 0 && content - space > UIMetrics.promptOverflowSlack
    }

    static func dropped(frame: CGRect, screens: [CGRect], margin: CGFloat) -> CGRect {
        guard let screen = screen(for: frame, in: screens) else { return frame }
        let origin = clamped(origin: frame.origin, size: frame.size, screen: screen, margin: margin)
        return CGRect(origin: origin, size: frame.size)
    }

    static func clamped(origin: CGPoint, size: CGSize, screen: CGRect, margin: CGFloat) -> CGPoint {
        let area = screen.insetBy(dx: margin, dy: margin)
        let x = size.width > area.width ? area.minX : min(max(origin.x, area.minX), area.maxX - size.width)
        let y = size.height > area.height ? area.maxY - size.height : min(max(origin.y, area.minY), area.maxY - size.height)
        return CGPoint(x: x, y: y)
    }

    static func screen(for frame: CGRect, in screens: [CGRect]) -> CGRect? {
        let overlapping = screens.filter { area(frame.intersection($0)) > 0 }
        if let most = overlapping.max(by: { area(frame.intersection($0)) < area(frame.intersection($1)) }) { return most }
        let center = CGPoint(x: frame.midX, y: frame.midY)
        return screens.min { distance(center, $0) < distance(center, $1) }
    }

    private static func area(_ rect: CGRect) -> CGFloat {
        rect.isNull ? 0 : rect.width * rect.height
    }

    private static func distance(_ point: CGPoint, _ rect: CGRect) -> CGFloat {
        let dx = max(rect.minX - point.x, 0, point.x - rect.maxX)
        let dy = max(rect.minY - point.y, 0, point.y - rect.maxY)
        return (dx * dx + dy * dy).squareRoot()
    }
}
