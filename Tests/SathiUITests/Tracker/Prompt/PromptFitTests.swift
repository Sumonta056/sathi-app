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

    private let left = CGRect(x: 0, y: 0, width: 1440, height: 900)
    private let right = CGRect(x: 1440, y: 0, width: 1920, height: 1080)

    private func drop(_ frame: CGRect) -> CGRect {
        PromptFit.dropped(frame: frame, screens: [left, right], margin: margin)
    }

    @Test func aLargeScreenGivesTheFixedSize() {
        let size = PromptFit.size(screen: CGRect(x: 0, y: 0, width: 1920, height: 1080), margin: 16)
        #expect(size == CGSize(width: UIMetrics.activityPromptWidth, height: UIMetrics.activityPromptHeight))
        #expect(size == CGSize(width: 1040, height: 720))
    }

    @Test func aShortScreenShrinksTheHeightToTheScreenLessBothMargins() {
        let size = PromptFit.size(screen: CGRect(x: 0, y: 25, width: 1440, height: 700), margin: 16)
        #expect(size == CGSize(width: 1040, height: 668))
    }

    @Test func aNarrowScreenShrinksTheWidthToTheScreenLessBothMargins() {
        let size = PromptFit.size(screen: CGRect(x: 0, y: 0, width: 1000, height: 900), margin: 16)
        #expect(size == CGSize(width: 968, height: 720))
    }

    @Test func aScreenOf752FitsExactlyAndSmallerScrolls() {
        let fits = CGRect(x: 0, y: 0, width: 1440, height: 752)
        let short = CGRect(x: 0, y: 0, width: 1440, height: 751)
        #expect(PromptFit.size(screen: fits, margin: 16).height == 720)
        #expect(PromptFit.size(screen: short, margin: 16).height == 719)
        #expect(!PromptFit.scrolls(screen: fits, margin: 16))
        #expect(PromptFit.scrolls(screen: short, margin: 16))
    }

    @Test func aFrameInsideOneScreenIsDroppedWhereItIs() {
        let frame = CGRect(x: 100, y: 100, width: 880, height: 400)
        #expect(drop(frame) == frame)
        let onRight = CGRect(x: 1600, y: 200, width: 880, height: 400)
        #expect(drop(onRight) == onRight)
    }

    @Test func aFrameAcrossTwoScreensMovesToTheOneWithTheLargerPart() {
        let mostlyLeft = CGRect(x: 800, y: 100, width: 880, height: 400)
        let movedLeft = drop(mostlyLeft)
        #expect(left.insetBy(dx: margin, dy: margin).contains(movedLeft))
        #expect(movedLeft.size == mostlyLeft.size)
        let mostlyRight = CGRect(x: 1100, y: 100, width: 880, height: 400)
        let movedRight = drop(mostlyRight)
        #expect(right.insetBy(dx: margin, dy: margin).contains(movedRight))
        #expect(movedRight.size == mostlyRight.size)
    }

    @Test func aDroppedFrameIsInsideTheMarginsVertically() {
        let low = CGRect(x: 1500, y: -100, width: 880, height: 400)
        #expect(drop(low).minY == right.minY + margin)
        let high = CGRect(x: 1500, y: 900, width: 880, height: 400)
        #expect(drop(high).maxY == right.maxY - margin)
    }

    @Test func aFrameBeyondEveryScreenLandsInsideTheNearest() {
        let off = CGRect(x: 3300, y: 100, width: 880, height: 400)
        #expect(right.insetBy(dx: margin, dy: margin).contains(drop(off)))
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
