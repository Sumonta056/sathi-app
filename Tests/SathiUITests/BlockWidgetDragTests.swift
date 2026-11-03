import CoreGraphics
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Block widget drag")
struct BlockWidgetDragTests {
    @Test func theFirstDragStepDoesNotMove() {
        #expect(BlockWidget.dragStep(from: nil, to: CGPoint(x: 40, y: 12)) == .zero)
    }

    @Test(arguments: [
        (CGPoint(x: 10, y: 20), CGPoint(x: 25, y: 27), CGSize(width: 15, height: 7)),
        (CGPoint(x: 50, y: 40), CGPoint(x: 30, y: 15), CGSize(width: -20, height: -25)),
        (CGPoint(x: 8, y: 8), CGPoint(x: 8, y: 8), CGSize.zero),
    ])
    func eachDragStepIsTheDistanceSinceTheLastPoint(_ last: CGPoint, _ now: CGPoint, _ expected: CGSize) {
        #expect(BlockWidget.dragStep(from: last, to: now) == expected)
    }

    @Test func thePillIsWider() {
        #expect(UIMetrics.blockWidgetWidth == 320)
    }

    @Test func theRingTitleAndTimerSitInADraggableArea() throws {
        let sut = try Block.view(BlockWidget(onMove: { _ in }), Block.running(.minutes(30), after: 5))
        let drag = try sut.find(viewWithAccessibilityIdentifier: "block.widget.drag")
        #expect(throws: Never.self) { try drag.gesture(DragGesture.self) }
        #expect(throws: Never.self) { try drag.find(text: "Plan") }
        #expect(throws: Never.self) { try drag.find(viewWithAccessibilityIdentifier: "block.widget.timer") }
    }

    @Test func theEndButtonIsOutsideTheDraggableArea() throws {
        let sut = try Block.view(BlockWidget(), Block.running(.minutes(30), after: 5))
        let drag = try sut.find(viewWithAccessibilityIdentifier: "block.widget.drag")
        #expect((try? drag.find(viewWithAccessibilityIdentifier: "block.widget.end")) == nil)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "block.widget.end") }
    }

    @Test func theEndButtonStillEndsTheBlockWithAMoveHandler() throws {
        let h = Block.running(.minutes(30), after: 18)
        var moved: [CGSize] = []
        try Block.tap(Block.view(BlockWidget(onMove: { moved.append($0) }), h), id: "block.widget.end")
        #expect(h.engine.timeBlock == nil)
        #expect(moved.isEmpty)
    }
}
