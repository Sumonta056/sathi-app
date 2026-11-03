import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Block done popup")
struct BlockDonePopupTests {
    @Test func showsEyebrowSummaryAndSavedLine() throws {
        let sut = try Block.view(BlockDonePopup(), Block.finished())
        let start = Block.clock(Block.now)
        let end = Block.clock(Block.now.addingTimeInterval(30 * 60))
        #expect(throws: Never.self) { try sut.find(text: "TIME BLOCK · DONE") }
        #expect(throws: Never.self) { try sut.find(text: "30 min on Plan") }
        #expect(throws: Never.self) { try sut.find(text: "Saved to Gmail Work · " + start + " – " + end) }
    }

    @Test func offersDoneAndFifteenMoreMinutes() throws {
        let sut = try Block.view(BlockDonePopup(), Block.finished())
        #expect(throws: Never.self) { try sut.find(text: "Done") }
        #expect(throws: Never.self) { try sut.find(text: "+15 min") }
    }

    @Test func doneDismissesThePopup() throws {
        let h = Block.finished()
        try Block.tap(Block.view(BlockDonePopup(), h), id: "block.done.done")
        #expect(h.engine.finishedBlock == nil)
        #expect(h.presenter.calls.last == .closeBlockDone)
    }

    @Test func doneKeepsTheSavedEventAndStartsNothing() throws {
        let h = Block.finished()
        try Block.tap(Block.view(BlockDonePopup(), h), id: "block.done.done")
        #expect(h.engine.timeBlock == nil)
        #expect(h.calendarWriter.saved.count == 1)
    }

    @Test func extendRunsTheBlockFifteenMoreMinutes() throws {
        let h = Block.finished()
        try Block.tap(Block.view(BlockDonePopup(), h), id: "block.done.extend")
        let block = try #require(h.engine.timeBlock)
        #expect(!block.waitingForCalendar)
        #expect(block.plannedEnd == Block.now.addingTimeInterval(45 * 60))
        #expect(h.engine.finishedBlock == nil)
        #expect(h.presenter.calls.contains(.closeBlockDone))
    }
}
