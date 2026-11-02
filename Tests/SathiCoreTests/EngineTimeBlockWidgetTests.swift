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

    @Test func widgetShowsTheNoteThenThePill() throws {
        let h = widget()
        h.startBlock("Plan", .minutes(30))
        let note = BlockNote.started(title: "Plan", length: .minutes(30), end: t0.addingTimeInterval(30 * Timing.minute), calendarTitle: "Gmail Work")
        let calls = h.presenter.calls
        let noteAt = try #require(calls.firstIndex(of: .showBlockNote(note)))
        let pillAt = try #require(calls.firstIndex(of: .showBlockWidget))
        #expect(noteAt < pillAt)
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
