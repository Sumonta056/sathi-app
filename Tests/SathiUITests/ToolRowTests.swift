import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Tool row")
struct ToolRowTests {
    @Test func idleMenuShowsBothToolsAndNoToolCards() throws {
        let sut = try Glance.panel(Glance.harness())
        #expect(sut.findAll(ToolRow.self).count == 1)
        #expect(Glance.toolTexts(sut).contains("Reminder"))
        #expect(Glance.toolTexts(sut).contains("Time block"))
        #expect(Glance.toolButtons(sut) == 2)
        #expect(!MenuFind.texts(sut).contains("Quick reminders"))
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "block.start")) == nil)
        #expect(Find.lacks(sut, text: "End now"))
    }

    @Test func oneReminderShowsTheQuickCardAndOnlyTheTimeBlockTool() throws {
        let sut = try Glance.panel(Glance.harness(reminders: 1))
        #expect(MenuFind.texts(sut).contains("Quick reminders"))
        #expect(Glance.toolTexts(sut).contains("Time block"))
        #expect(!Glance.toolTexts(sut).contains("Reminder"))
        #expect(Glance.toolButtons(sut) == 1)
    }

    @Test func runningBlockShowsTheBlockCardAndOnlyTheReminderTool() throws {
        let sut = try Glance.panel(Glance.harness(block: .minutes(30)))
        #expect(throws: Never.self) { try sut.find(button: "End now") }
        #expect(Glance.toolTexts(sut).contains("Reminder"))
        #expect(!Glance.toolTexts(sut).contains("Time block"))
        #expect(Glance.toolButtons(sut) == 1)
    }

    @Test func reminderAndRunningBlockLeaveNoToolButtons() throws {
        let sut = try Glance.panel(Glance.harness(reminders: 1, block: .open))
        #expect(MenuFind.texts(sut).contains("Quick reminders"))
        #expect(throws: Never.self) { try sut.find(button: "End now") }
        #expect(Glance.toolButtons(sut) == 0)
        #expect(Glance.toolTexts(sut).isEmpty)
    }

    @Test func deniedAccessShowsTheExplanationAndNoTimeBlockTool() throws {
        let sut = try Glance.panel(Glance.harness(denied: true))
        #expect(throws: Never.self) { try sut.find(text: "Sathi needs calendar access to save your time blocks.") }
        #expect(!Glance.toolTexts(sut).contains("Time block"))
        #expect(Glance.toolTexts(sut).contains("Reminder"))
    }

    @Test func reminderButtonOpensTheAddPopup() throws {
        let h = Glance.harness()
        try Find.button(hosted(ToolRow(), h).inspect(), holding: "Reminder").tap()
        #expect(h.presenter.calls.last == .showQuickAdd)
    }

    @Test func menuNeverHoldsTheAddForm() throws {
        #expect(try Glance.panel(Glance.harness()).findAll(QuickAddForm.self).isEmpty)
    }

    @Test func reminderButtonHasAClearLabel() throws {
        let sut = try hosted(ToolRow(), Glance.harness()).inspect()
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityLabel: Copywriter.quickToolButton) }
    }

    @Test func timeBlockButtonOpensTheStartPopup() throws {
        let h = Glance.harness()
        let sut = try hosted(ToolRow(), h).inspect()
        try Find.button(sut, holding: "Time block").tap()
        #expect(h.presenter.calls.last == .showBlockStart)
    }
}
