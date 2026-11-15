import CoreGraphics
@testable import SathiUI
import Testing

@Suite("Prompt fit")
struct PromptFitTests {
    private let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
    private let margin: CGFloat = 20
    private let size = CGSize(width: 880, height: 400)

    private func clamp(_ x: CGFloat, _ y: CGFloat, _ size: CGSize? = nil, on screen: CGRect? = nil) -> CGPoint {
        PromptFit.clamped(origin: CGPoint(x: x, y: y), size: size ?? self.size, screen: screen ?? self.screen, margin: margin)
    }

    @Test func theMaxHeightIsTheScreenLessBothMargins() {
        #expect(PromptFit.maxHeight(screen: screen, margin: margin) == 860)
        #expect(PromptFit.maxHeight(screen: CGRect(x: 0, y: 25, width: 1280, height: 775), margin: 12) == 751)
    }

    @Test func aFrameInsideStaysWhereItIs() {
        #expect(clamp(100, 100) == CGPoint(x: 100, y: 100))
        #expect(clamp(20, 20) == CGPoint(x: 20, y: 20))
    }

    @Test func aFrameBelowTheBottomMovesUp() {
        #expect(clamp(100, -50) == CGPoint(x: 100, y: 20))
    }

    @Test func aFrameAboveTheTopMovesDown() {
        #expect(clamp(100, 600) == CGPoint(x: 100, y: 480))
    }

    @Test func aFramePastTheRightMovesLeft() {
        #expect(clamp(1000, 100) == CGPoint(x: 540, y: 100))
    }

    @Test func aFramePastTheLeftMovesRight() {
        #expect(clamp(-10, 100) == CGPoint(x: 20, y: 100))
    }

    @Test func aFrameTallerThanTheScreenAlignsItsTopToTheTopMargin() {
        let tall = CGSize(width: 880, height: 1000)
        #expect(clamp(100, 0, tall) == CGPoint(x: 100, y: -120))
        #expect(clamp(100, 300, tall) == CGPoint(x: 100, y: -120))
    }

    @Test func aFrameWiderThanTheScreenAlignsItsLeftToTheLeftMargin() {
        let wide = CGSize(width: 1500, height: 400)
        #expect(clamp(-200, 100, wide) == CGPoint(x: 20, y: 100))
        #expect(clamp(300, 100, wide) == CGPoint(x: 20, y: 100))
    }

    @Test func aScreenThatDoesNotStartAtZeroUsesItsOwnEdges() {
        let right = CGRect(x: 1440, y: 100, width: 1920, height: 1080)
        #expect(clamp(3000, 50, on: right) == CGPoint(x: 2460, y: 120))
        #expect(clamp(1400, 1000, on: right) == CGPoint(x: 1460, y: 760))
    }
}
