import CoreGraphics
@testable import SathiUI
import Testing

@Suite("Window fit")
struct WindowFitTests {
    private let screenA = CGRect(x: 0, y: 40, width: 1440, height: 835)
    private let screenB = CGRect(x: 1440, y: 0, width: 1920, height: 1055)
    private let small = CGRect(x: -1280, y: 25, width: 1280, height: 775)
    private let tol = UIMetrics.windowFitTolerance

    private func moved(_ frame: CGRect, from: CGRect, to: CGRect) -> CGRect {
        WindowFit.moved(frame: frame, from: from, to: to, tolerance: tol)
    }

    @Test func openFrameIsThePointerDisplayVisibleFrame() {
        #expect(WindowFit.openFrame(visible: screenA) == screenA)
        #expect(WindowFit.openFrame(visible: screenB) == screenB)
    }

    @Test func toleranceIsAFewPixels() {
        #expect(tol >= 2)
        #expect(tol <= 16)
    }

    @Test func fullWindowFillsTheNewDisplay() {
        #expect(moved(screenA, from: screenA, to: screenB) == screenB)
    }

    @Test func fullWindowWithTilingGapsStillCountsAsFull() {
        let gapped = screenA.insetBy(dx: tol / 2, dy: tol / 2)
        #expect(moved(gapped, from: screenA, to: screenB) == screenB)
    }

    @Test func leftHalfStaysLeftHalf() {
        let left = CGRect(x: 0, y: 40, width: 720, height: 835)
        let expected = CGRect(x: 1440, y: 0, width: 960, height: 1055)
        #expect(moved(left, from: screenA, to: screenB) == expected)
    }

    @Test func rightHalfStaysRightHalf() {
        let right = CGRect(x: 720, y: 40, width: 720, height: 835)
        let expected = CGRect(x: 1440 + 960, y: 0, width: 960, height: 1055)
        #expect(moved(right, from: screenA, to: screenB) == expected)
    }

    @Test func leftHalfWithTilingGapStillCountsAsLeftHalf() {
        let left = CGRect(x: 0 + tol / 2, y: 40 + tol / 2, width: 720 - tol, height: 835 - tol)
        let expected = CGRect(x: 1440, y: 0, width: 960, height: 1055)
        #expect(moved(left, from: screenA, to: screenB) == expected)
    }

    @Test func rightHalfMovesToSmallerDisplayRightHalf() {
        let right = CGRect(x: 960, y: 0, width: 960, height: 1055)
        let expected = CGRect(x: -640, y: 25, width: 640, height: 775)
        #expect(moved(right, from: CGRect(x: 0, y: 0, width: 1920, height: 1055), to: small) == expected)
    }

    @Test func freeLargerSizeShrinksAndMovesInside() {
        let free = CGRect(x: 1500, y: 100, width: 1700, height: 900)
        let result = moved(free, from: screenB, to: screenA)
        #expect(result.width == screenA.width)
        #expect(result.height == screenA.height)
        #expect(screenA.contains(result))
    }

    @Test func freeSizeLargerInOneAxisShrinksOnlyThatAxis() {
        let free = CGRect(x: 1500, y: 100, width: 1000, height: 1000)
        let result = moved(free, from: screenB, to: screenA)
        #expect(result.width == 1000)
        #expect(result.height == screenA.height)
        #expect(screenA.contains(result))
    }

    @Test func freeSmallerSizeKeepsSizeAndMovesInside() {
        let free = CGRect(x: 2400, y: 600, width: 800, height: 500)
        let result = moved(free, from: screenB, to: screenA)
        #expect(result.size == free.size)
        #expect(screenA.contains(result))
    }

    @Test func freeSmallerSizeAlreadyInsideTargetStaysPut() {
        let free = CGRect(x: 100, y: 100, width: 600, height: 500)
        #expect(moved(free, from: screenA, to: screenA) == free)
    }

    @Test func mainWindowConstants() {
        #expect(UIMetrics.mainWindowMinSize == CGSize(width: 640, height: 520))
        #expect(UIMetrics.mainNarrowBelow == 900)
        #expect(UIMetrics.mainDrawerBelow == 1100)
        #expect(UIMetrics.mainDragStripHeight == 28)
        #expect(UIMetrics.mainDragStripPageInset == 12)
        #expect(UIMetrics.mainDragStripPageInset == UIMetrics.mainDragStripHeight - UIMetrics.mainContentPadding.top)
    }
}
