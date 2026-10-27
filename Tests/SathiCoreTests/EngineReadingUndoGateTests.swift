import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine reading undo gate")
struct EngineReadingUndoGateTests {
    @Test func undoIsOpenWhileTheUnreadQueueHasRoom() {
        let h = Shelf.harness(Shelf.unreadMany(Limits.readingListMax - 1) + [Shelf.read("r", on: "2026-03-02")])
        #expect(h.engine.canUndoReading)
    }

    @Test func undoIsClosedWhenTheUnreadQueueIsFull() {
        let h = Shelf.harness(Shelf.unreadMany(Limits.readingListMax) + [Shelf.read("r", on: "2026-03-02")])
        #expect(!h.engine.canUndoReading)
    }
}
