import AppKit
import SwiftUI

struct CalendarDot: View {
    let hex: UInt32
    var size: CGFloat = UIMetrics.blockDot

    var body: some View {
        Circle().fill(Color(hex: hex)).frame(width: size, height: size)
    }

    @MainActor
    static func image(_ hex: UInt32) -> NSImage {
        if let cached = cache[hex] { return cached }
        let side = UIMetrics.blockListDot
        let img = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            NSColor(Color(hex: hex)).setFill()
            NSBezierPath(ovalIn: rect).fill()
            return true
        }
        img.isTemplate = false
        cache[hex] = img
        return img
    }

    @MainActor private static var cache: [UInt32: NSImage] = [:]
}
