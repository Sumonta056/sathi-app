import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Block start popup")
struct BlockStartPopupTests {
    private func startButton(_ sut: InspectableView<some BaseViewType>) throws -> InspectableView<ViewType.Button> {
        try sut.find(viewWithAccessibilityIdentifier: "block.start").find(ViewType.Button.self, relation: .parent)
    }

    @Test func showsEyebrowPromptAndPieces() throws {
        let sut = try Block.popup(Block.harness())
        #expect(throws: Never.self) { try sut.find(text: "NEW TIME BLOCK") }
        #expect(throws: Never.self) { try sut.find(text: "What are you working on?") }
        #expect(sut.findAll(LengthChips.self).count == 1)
        #expect(sut.findAll(CalendarMenu.self).count == 1)
        #expect(sut.findAll(LazyTextField.self).count == 1)
    }

    @Test func startLabelShowsTheEndForAPlannedLength() throws {
        let sut = try Block.popup(Block.harness())
        let end = Block.clock(Block.now.addingTimeInterval(30 * 60))
        #expect(throws: Never.self) { try sut.find(text: "Start · ends at " + end) }
    }

    @Test func startLabelFollowsTheLastLength() throws {
        let h = Block.harness { $0.prefs.timeBlock.lastLength = .minutes(45) }
        let end = Block.clock(Block.now.addingTimeInterval(45 * 60))
        #expect(throws: Never.self) { try Block.popup(h).find(text: "Start · ends at " + end) }
    }

    @Test func startLabelIsPlainForAnOpenBlock() throws {
        let h = Block.harness { $0.prefs.timeBlock.lastLength = .open }
        let sut = try Block.popup(h)
        #expect(throws: Never.self) { try sut.find(text: "Start") }
        #expect(!MenuFind.hasText(sut, containing: "ends at"))
    }

    @Test func startCallsTheEngineWithTheLastLengthAndDefaultCalendar() throws {
        let h = Block.harness { $0.prefs.timeBlock.lastLength = .minutes(45) }
        try startButton(Block.popup(h)).tap()
        let block = try #require(h.engine.timeBlock)
        #expect(block.length == .minutes(45))
        #expect(block.calendarID == "work")
        #expect(block.title == Copywriter.blockDefaultTitle)
        #expect(block.startedAt == Block.now)
    }

    @Test func startUsesTheSavedDefaultCalendar() throws {
        let h = Block.harness { $0.prefs.timeBlock.defaultCalendarID = "home" }
        try startButton(Block.popup(h)).tap()
        #expect(h.engine.timeBlock?.calendarID == "home")
    }

    @Test func startClosesThePopup() throws {
        let h = Block.harness()
        try startButton(Block.popup(h)).tap()
        #expect(h.presenter.calls.contains(.closeBlockStart))
    }

    @Test func startAnOpenBlockHasNoEnd() throws {
        let h = Block.harness { $0.prefs.timeBlock.lastLength = .open }
        try startButton(Block.popup(h)).tap()
        #expect(h.engine.timeBlock?.length == .open)
        #expect(h.engine.timeBlock?.plannedEnd == nil)
    }
}
