import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Time block card")
struct TimeBlockCardTests {
    @Test func idleRendersNothing() throws {
        let sut = try Block.card(Block.harness())
        #expect(MenuFind.texts(sut).isEmpty)
        #expect(sut.findAll(ViewType.Button.self).isEmpty)
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "block.start")) == nil)
    }

    @Test func toolRowTimeBlockOpensTheStartPopup() throws {
        let h = Block.harness()
        try Find.button(hosted(ToolRow(), h).inspect(), holding: "Time block").tap()
        #expect(h.presenter.calls.last == .showBlockStart)
    }

    @Test func noAccessShowsTheExplanationAndSettingsLink() throws {
        let sut = try Block.card(Block.denied())
        #expect(throws: Never.self) { try sut.find(text: "Sathi needs calendar access to save your time blocks.") }
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "block.openSettings") }
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "block.start")) == nil)
    }

    @Test func openSystemSettingsOpensTheCalendarPrivacyPane() throws {
        let h = Block.denied()
        try Block.card(h).find(viewWithAccessibilityIdentifier: "block.openSettings").find(ViewType.Button.self, relation: .parent).tap()
        let url = "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
        #expect(h.links.opened.map(\.absoluteString) == [url])
    }

    @Test func plannedBlockShowsProgressTitleAndEnd() throws {
        let h = Block.running(.minutes(30), after: 18)
        let sut = try Block.card(h)
        let end = Block.clock(Block.now.addingTimeInterval(30 * 60))
        #expect(throws: Never.self) { try sut.find(text: "18 of 30 min · ends at " + end) }
        #expect(throws: Never.self) { try sut.find(button: "End now") }
        #expect(throws: Never.self) { try sut.find(text: "Plan") }
        #expect(sut.findAll(CalendarMenu.self).count == 1)
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "block.start")) == nil)
    }

    @Test func plannedBlockUsesTheBlockLengthAsTotal() throws {
        let h = Block.running(.minutes(45), after: 10)
        let sut = try Block.card(h)
        let end = Block.clock(Block.now.addingTimeInterval(45 * 60))
        #expect(throws: Never.self) { try sut.find(text: "10 of 45 min · ends at " + end) }
    }

    @Test func openBlockShowsSinceAndMinutes() throws {
        let h = Block.running(.open, after: 42)
        let sut = try Block.card(h)
        #expect(throws: Never.self) { try sut.find(text: "Since " + Block.clock(Block.now) + " · 42 min") }
        #expect(MenuFind.texts(sut).allSatisfy { !$0.contains(" of ") })
    }

    @Test func endNowEndsTheBlock() throws {
        let h = Block.running(.minutes(30), after: 18)
        try Block.card(h).find(button: "End now").tap()
        #expect(h.engine.timeBlock == nil)
        #expect(h.calendarWriter.saved.count == 1)
    }

    @Test func titleFieldIsALazyFieldHoldingTheTitle() throws {
        let h = Block.running(.minutes(30), after: 5)
        let field = try Block.card(h).find(LazyTextField.self).actualView()
        #expect(field.text == "Plan")
    }

    @Test func submittingTheTitleKeepsTheTitle() throws {
        let h = Block.running(.minutes(30), after: 5)
        try Block.card(h).find(LazyTextField.self).actualView().onSubmit()
        #expect(h.engine.timeBlock?.title == "Plan")
    }

    @Test func waitingBlockListsCalendarsAndSaveHere() throws {
        let h = Block.waiting()
        let sut = try Block.card(h)
        let texts = MenuFind.texts(sut)
        #expect(texts.contains("Gmail Work"))
        #expect(texts.contains("Home"))
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "block.saveHere") }
        #expect(Find.lacks(sut, text: "End now"))
    }

    @Test func saveHereWritesTheBlockToTheChosenCalendar() throws {
        let h = Block.waiting()
        h.calendarWriter.nextSaveResult = nil
        try Block.card(h).find(viewWithAccessibilityIdentifier: "block.saveHere").find(ViewType.Button.self, relation: .parent).tap()
        #expect(h.calendarWriter.saved.count == 2)
        #expect(h.calendarWriter.saved.last?.calendarID == "work")
        #expect(h.engine.timeBlock == nil)
    }

    @Test func menuPanelHoldsOneCardAfterTheQuickList() throws {
        let h = Quick.harness([Quick.item("A", minutes: 5)])
        h.startBlock("Plan", .minutes(30))
        let sut = try hosted(MenuPanel(), h).inspect()
        #expect(sut.findAll(TimeBlockCard.self).count == 1)
        let texts = MenuFind.texts(sut)
        let quick = try #require(texts.firstIndex(of: "Quick reminders"))
        let block = try #require(texts.firstIndex(of: "End now"))
        #expect(quick < block)
    }
}
