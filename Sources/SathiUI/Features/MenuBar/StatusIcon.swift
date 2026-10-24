import AppKit

@MainActor
enum StatusIcon {
    private static var cache: [Double: NSImage] = [:]

    static func image(level: Double) -> NSImage {
        if let cached = cache[level] { return cached }
        let image = draw(level: level)
        cache[level] = image
        return image
    }

    private static func draw(level: Double) -> NSImage {
        let img = NSImage(size: UIMetrics.statusIconSize, flipped: true) { rect in
            guard let cg = NSGraphicsContext.current?.cgContext else { return false }
            let s = rect.height / 124
            cg.translateBy(x: (rect.width - 100 * s) / 2, y: 0)
            cg.scaleBy(x: s, y: s)
            let drop = BuddyPaths.drop().cgPath
            cg.setFillColor(NSColor.black.withAlphaComponent(0.2).cgColor)
            cg.addPath(drop)
            cg.fillPath()
            cg.saveGState()
            cg.addPath(drop)
            cg.clip()
            cg.setFillColor(NSColor.black.cgColor)
            let top = 116 - CGFloat(level) * 112
            cg.fill(CGRect(x: 0, y: top, width: 100, height: 124 - top))
            cg.restoreGState()
            cg.setStrokeColor(NSColor.black.cgColor)
            cg.setLineWidth(10)
            cg.addPath(drop)
            cg.strokePath()
            return true
        }
        img.isTemplate = true
        return img
    }
}
