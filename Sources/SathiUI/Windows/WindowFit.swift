import CoreGraphics

enum WindowFit {
    private enum Shape {
        case full, left, right, free
    }

    static func openFrame(visible: CGRect) -> CGRect {
        visible
    }

    static func shouldFillOnShow(isNewWindow: Bool, isVisible: Bool, isMiniaturized: Bool) -> Bool {
        isNewWindow || !isVisible || isMiniaturized
    }

    static func shouldRecordShape(fitting: Bool, pendingFit: Bool, mouseDown: Bool, inLiveResize: Bool) -> Bool {
        !fitting && !pendingFit && !mouseDown && !inLiveResize
    }

    static func moved(frame: CGRect, from: CGRect, to: CGRect, tolerance: CGFloat) -> CGRect {
        switch shape(frame, in: from, tolerance: tolerance) {
        case .full:
            return to
        case .left:
            return CGRect(x: to.minX, y: to.minY, width: to.width / 2, height: to.height)
        case .right:
            return CGRect(x: to.midX, y: to.minY, width: to.width / 2, height: to.height)
        case .free:
            return clamped(frame, into: to)
        }
    }

    private static func shape(_ frame: CGRect, in area: CGRect, tolerance: CGFloat) -> Shape {
        func near(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) <= tolerance }
        guard near(frame.minY, area.minY), near(frame.maxY, area.maxY) else { return .free }
        if near(frame.minX, area.minX), near(frame.maxX, area.maxX) { return .full }
        guard near(frame.width, area.width / 2) else { return .free }
        if near(frame.minX, area.minX) { return .left }
        if near(frame.maxX, area.maxX) { return .right }
        return .free
    }

    private static func clamped(_ frame: CGRect, into area: CGRect) -> CGRect {
        let width = min(frame.width, area.width)
        let height = min(frame.height, area.height)
        let x = min(max(frame.minX, area.minX), area.maxX - width)
        let y = min(max(frame.minY, area.minY), area.maxY - height)
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
