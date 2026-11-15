import CoreGraphics
@testable import SathiUI
import Testing

@Suite("Window fit pre-move")
struct WindowFitPreMoveTests {
    private let screenA = CGRect(x: 0, y: 40, width: 1440, height: 835)
    private let screenB = CGRect(x: 1440, y: 0, width: 1920, height: 1055)
    private let tol = UIMetrics.windowFitTolerance

    @Test func fullWindowDraggedFarKeepsFullWhenJudgedByItsPreMoveFrame() {
        let dragged = screenA.offsetBy(dx: 900, dy: 120)
        let freeResult = WindowFit.moved(frame: dragged, from: screenA, to: screenB, tolerance: tol)
        let keptResult = WindowFit.moved(frame: screenA, from: screenA, to: screenB, tolerance: tol)
        #expect(freeResult != screenB)
        #expect(keptResult == screenB)
    }

    @Test func leftHalfDraggedFarKeepsLeftHalfWhenJudgedByItsPreMoveFrame() {
        let half = CGRect(x: 0, y: 40, width: 720, height: 835)
        let result = WindowFit.moved(frame: half, from: screenA, to: screenB, tolerance: tol)
        #expect(result == CGRect(x: 1440, y: 0, width: 960, height: 1055))
    }
}
