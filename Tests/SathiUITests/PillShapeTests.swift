import AppKit
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Pill shape")
struct PillShapeTests {
    private let size = CGSize(width: 100, height: 32)
    private let margin: CGFloat = 4

    private func inkColumn(_ border: some View, x: CGFloat) throws -> Double {
        let view = border.frame(width: size.width, height: size.height).padding(margin).background(Color.black)
        let host = NSHostingView(rootView: view)
        let full = CGSize(width: size.width + 2 * margin, height: size.height + 2 * margin)
        host.frame = CGRect(origin: .zero, size: full)
        let window = NSWindow(contentRect: host.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        let rep = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: rep)
        let scale = Double(rep.pixelsWide) / full.width
        let px = Int((x + margin) * scale)
        let rows = Int((margin + 6) * scale) ..< Int((margin + 10) * scale)
        return rows.map { Double(rep.colorAt(x: px, y: $0)?.usingColorSpace(.sRGB)?.redComponent ?? 0) }.max() ?? 0
    }

    @Test(arguments: [-1.0, -0.5, 0.0])
    func roundEndsDrawNoInkBesideTheCurve(_ offset: Double) throws {
        let border = Pill().strokeBorder(Color.white, lineWidth: 1)
        #expect(try inkColumn(border, x: offset) < 0.2)
        #expect(try inkColumn(border, x: size.width - 1 - offset) < 0.2)
    }

    @Test func curveDrawsTheBorder() throws {
        let border = Pill().strokeBorder(Color.white, lineWidth: 1)
        #expect(try inkColumn(border, x: 3) > 0.3)
    }
}
