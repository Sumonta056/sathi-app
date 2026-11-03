import AppKit
@testable import SathiUI
import Testing

@MainActor
@Suite("Menu window fit")
struct MenuWindowFitTests {
    private let tall = NSRect(x: 862, y: 100, width: 380, height: 738)

    @Test func shorterContentKeepsTheTopEdge() {
        let fit = MenuWindowFit.frame(tall, height: 607)
        #expect(fit.maxY == tall.maxY)
        #expect(fit.height == 607)
    }

    @Test func tallerContentKeepsTheTopEdge() {
        let fit = MenuWindowFit.frame(tall, height: 800)
        #expect(fit.maxY == tall.maxY)
        #expect(fit.height == 800)
    }

    @Test func leftEdgeAndWidthStay() {
        let fit = MenuWindowFit.frame(tall, height: 607)
        #expect(fit.minX == tall.minX)
        #expect(fit.width == tall.width)
    }

    @Test func sameHeightNeedsNoChange() {
        #expect(!MenuWindowFit.needsFit(tall, height: 738))
        #expect(MenuWindowFit.needsFit(tall, height: 607))
    }
}
