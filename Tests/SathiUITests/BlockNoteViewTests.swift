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
    private func note(_ h: EngineHarness, _ note: BlockNote) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(BlockNoteView(note: note), h).inspect()
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
