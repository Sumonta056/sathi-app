import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine time block display")
struct EngineTimeBlockWidgetTests {
    private let t0 = day(2026, 3, 4, 10)

    private func widget() -> EngineHarness {
        EngineHarness.quiet { $0.prefs.timeBlock.display = .widget }
    }

    @Test func widgetStartShowsThePillAndNoBlockNote() {
        let h = widget()
        h.startBlock("Plan", .minutes(30))
        #expect(h.presenter.calls.contains(.showBlockWidget))
        #expect(h.presenter.blockNotes.isEmpty)
    }

    @Test func undoEndsFourSecondsAfterTheStart() throws {
        let h = widget()
        h.startBlock("Plan", .minutes(30))
        let b = try #require(h.engine.timeBlock)
        #expect(b.undoEnd == b.startedAt.addingTimeInterval(4))
    }

    @Test func afterPlusFifteenTheUndoEndHasPassed() throws {
        let h = widget()
        h.startBlock("Plan", .minutes(15))
        h.advance(minutes: 15)
        h.engine.extendBlock()
        let b = try #require(h.engine.timeBlock)
        #expect(b.undoEnd < h.clock.now)
    }

    @Test func widgetClosesOnEnd() {
        let h = widget()
        h.startBlock()
        h.advance(minutes: 5)
        h.engine.endBlock()
        #expect(h.presenter.calls.contains(.closeBlockWidget))
    }

    @Test func widgetClosesOnAutoEnd() {
        let h = widget()
        h.startBlock("Plan", .minutes(15))
        h.advance(minutes: 15)
        #expect(h.presenter.calls.contains(.closeBlockWidget))
    }

    @Test func menuBarShowsNeitherNoteNorPill() {
        let h = EngineHarness.quiet()
        h.startBlock()
        #expect(h.presenter.blockNotes.isEmpty)
        #expect(!h.presenter.calls.contains(.showBlockWidget))
    }

    @Test func menuBarStillShowsTheDonePopup() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(15))
        h.advance(minutes: 15)
        #expect(h.presenter.calls.contains(.showBlockDone))
    }
}
