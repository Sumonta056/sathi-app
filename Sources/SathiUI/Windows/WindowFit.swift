import CoreGraphics

enum WindowFit {
    private enum Shape {
        case full, left, right, free
    }

    static func openFrame(saved: CGRect?, screens: [CGRect], pointer: CGRect, defaultSize: CGSize) -> CGRect {
        guard let saved else { return centered(defaultSize, in: pointer) }
        guard let home = screens.first(where: { isReachable(saved, on: $0) }) else { return clamped(saved, into: pointer) }
        let fits = saved.width <= home.width && saved.height <= home.height
        return fits ? saved : clamped(saved, into: home)
    }

    static func isReachable(_ frame: CGRect, on area: CGRect) -> Bool {
        let least = UIMetrics.mainWindowMinOnScreen
        let part = frame.intersection(area)
        guard !part.isNull, part.width >= least.width, part.height >= least.height else { return false }
        let strip = CGRect(x: frame.minX, y: frame.maxY - UIMetrics.mainDragStripHeight, width: frame.width, height: UIMetrics.mainDragStripHeight)
        let bar = strip.intersection(area)
        return !bar.isNull && bar.width >= least.width && bar.height >= UIMetrics.mainDragStripHeight
    }

    static func shouldPlaceOnShow(isNewWindow: Bool, isVisible: Bool, isMiniaturized: Bool) -> Bool {
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

    private static func centered(_ size: CGSize, in area: CGRect) -> CGRect {
        let width = min(size.width, area.width)
        let height = min(size.height, area.height)
        return CGRect(x: area.midX - width / 2, y: area.midY - height / 2, width: width, height: height)
    }

    private static func clamped(_ frame: CGRect, into area: CGRect) -> CGRect {
        let width = min(frame.width, area.width)
        let height = min(frame.height, area.height)
        let x = min(max(frame.minX, area.minX), area.maxX - width)
        let y = min(max(frame.minY, area.minY), area.maxY - height)
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
