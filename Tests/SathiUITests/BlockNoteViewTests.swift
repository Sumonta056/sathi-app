import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Block note")
struct BlockNoteViewTests {
    private func startedHarness(_ length: TimeBlockLength = .minutes(30)) -> (EngineHarness, BlockNote) {
        let h = Block.harness { $0.prefs.timeBlock.display = .widget }
        h.startBlock("Write spec", length)
        return (h, h.presenter.blockNotes[0])
    }

    private func note(_ h: EngineHarness, _ note: BlockNote) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(BlockNoteView(note: note), h).inspect()
    }

    @Test func startedNoteShowsTitleDetailAndUndo() throws {
        let (h, n) = startedHarness()
        let sut = try note(h, n)
        let end = Block.clock(Block.now.addingTimeInterval(30 * 60))
        #expect(throws: Never.self) { try sut.find(text: "Started · Write spec") }
        #expect(throws: Never.self) { try sut.find(text: "30 min · ends at " + end + " · Gmail Work") }
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "block.undo") }
    }

    @Test func undoRemovesTheRunningBlock() throws {
        let (h, n) = startedHarness()
        try note(h, n).find(viewWithAccessibilityIdentifier: "block.undo").find(ViewType.Button.self, relation: .parent).tap()
        #expect(h.engine.timeBlock == nil)
        #expect(h.calendarWriter.saved.isEmpty)
    }

    @Test func undoIgnoresAnOlderNoteWhenANewBlockRuns() throws {
        let (h, n) = startedHarness()
        h.advance(minutes: 5)
        h.startBlock("Second", .minutes(15))
        let second = h.engine.timeBlock?.id
        try note(h, n).find(viewWithAccessibilityIdentifier: "block.undo").find(ViewType.Button.self, relation: .parent).tap()
        #expect(h.engine.timeBlock?.id == second)
    }

    @Test func savedPreviousNoteShowsTheLine() throws {
        let h = Block.harness()
        let sut = try note(h, .savedPrevious(minutes: 42, title: "Inbox", calendarTitle: "Work"))
        #expect(throws: Never.self) { try sut.find(text: "Saved 42 min on Inbox to Work.") }
        #expect(Find.lacks(sut, text: "Undo"))
    }

    @Test func tooShortNoteShowsTheLine() throws {
        let sut = try note(Block.harness(), .tooShort)
        #expect(throws: Never.self) { try sut.find(text: "Too short, not saved.") }
        #expect(Find.lacks(sut, text: "Undo"))
    }
}
