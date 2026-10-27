import CoreGraphics

enum CornerLayout {
    static func origins(sizes: [CGSize], in frame: CGRect, inset: CGPoint, overlap: CGFloat, gap: CGFloat) -> [CGPoint] {
        let start = frame.maxY + inset.y
        var right = frame.maxX + inset.x
        var left = right
        var top = start
        var columnHasPanel = false
        var result: [CGPoint] = []
        for size in sizes {
            if columnHasPanel, top - size.height < frame.minY {
                right = left - gap
                left = right
                top = start
            }
            result.append(CGPoint(x: right - size.width, y: top - size.height))
            left = min(left, right - size.width)
            top -= size.height - overlap
            columnHasPanel = true
        }
        return result
    }
}
