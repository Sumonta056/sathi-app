import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Block widget undo")
struct BlockWidgetUndoTests {
    private func widget() -> EngineHarness {
        let h = Block.harness { $0.prefs.timeBlock.display = .widget }
        h.startBlock("Plan", .minutes(30))
        return h
    }

    private func block(_ h: EngineHarness) throws -> TimeBlock {
        try #require(h.engine.timeBlock)
    }

    @Test(arguments: [0.0, 1.0, 3.0, 3.9])
    func undoShowsBeforeTheDeadline(_ seconds: TimeInterval) throws {
        let b = try block(widget())
        #expect(BlockWidget.showsUndo(b, now: b.startedAt.addingTimeInterval(seconds)))
    }

    @Test(arguments: [4.0, 5.0, 60.0, 1800.0])
    func undoHidesAtAndAfterTheDeadline(_ seconds: TimeInterval) throws {
        let b = try block(widget())
        #expect(!BlockWidget.showsUndo(b, now: b.startedAt.addingTimeInterval(seconds)))
    }

    @Test func afterPlusFifteenThereIsNoUndo() throws {
        let h = Block.harness { $0.prefs.timeBlock.display = .widget }
        h.startBlock("Plan", .minutes(15))
        h.advance(minutes: 15)
        h.engine.extendBlock()
        #expect(try !BlockWidget.showsUndo(block(h), now: h.engine.now))
    }

    @Test func theUndoActionShowsUndoAndNoEnd() throws {
        let h = widget()
        let sut = try Block.view(BlockWidgetAction(block: block(h), showsUndo: true), h)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "block.widget.undo") }
        #expect(throws: Never.self) { try sut.find(text: Copywriter.blockUndo) }
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "block.widget.end")) == nil)
    }

    @Test func theEndActionShowsEndAndNoUndo() throws {
        let h = widget()
        let sut = try Block.view(BlockWidgetAction(block: block(h), showsUndo: false), h)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "block.widget.end") }
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "block.widget.undo")) == nil)
        #expect(Find.lacks(sut, text: Copywriter.blockUndo))
    }

    @Test func tappingUndoRemovesTheBlockAndSavesNothing() throws {
        let h = widget()
        let sut = try Block.view(BlockWidgetAction(block: block(h), showsUndo: true), h)
        try Block.tap(sut, id: "block.widget.undo")
        #expect(h.engine.timeBlock == nil)
        #expect(h.calendarWriter.saved.isEmpty)
        #expect(h.presenter.calls.contains(.closeBlockWidget))
    }

    @Test func undoOfAnOlderBlockKeepsTheNewOne() throws {
        let h = widget()
        let old = try block(h)
        h.advance(minutes: 5)
        h.startBlock("Second", .minutes(15))
        let second = h.engine.timeBlock?.id
        let sut = try Block.view(BlockWidgetAction(block: old, showsUndo: true), h)
        try Block.tap(sut, id: "block.widget.undo")
        #expect(h.engine.timeBlock?.id == second)
    }

    @Test func thePillLongAfterTheStartShowsEndAndNoUndo() throws {
        let h = widget()
        h.advance(minutes: 5)
        let sut = try Block.view(BlockWidget(), h)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "block.widget.end") }
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "block.widget.undo")) == nil)
    }
}
