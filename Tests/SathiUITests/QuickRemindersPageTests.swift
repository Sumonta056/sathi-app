import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Quick reminders page")
struct QuickRemindersPageTests {
    private func page(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(SettingsPageView(page: .quickReminders), h).inspect()
    }

    @Test func showsTheLevelAndCloseButtonCard() throws {
        let sut = try page(Quick.harness())
        #expect(throws: Never.self) { try sut.find(text: "Show a close button") }
        #expect(throws: Never.self) { try sut.find(text: "Nudgy") }
    }

    @Test func listsPendingReminders() throws {
        let sut = try page(Quick.harness([Quick.item("Call mom", minutes: 25), Quick.item("Invoice", minutes: 175)]))
        #expect(sut.findAll(QuickRow.self).count == 2)
        #expect(throws: Never.self) { try sut.find(text: "Call mom") }
        #expect(throws: Never.self) { try sut.find(text: "Invoice") }
    }

    @Test func deleteRemovesTheReminder() throws {
        let h = Quick.harness([Quick.item("Call mom", minutes: 25)])
        try page(h).find(viewWithAccessibilityLabel: "Delete this reminder").button().tap()
        #expect(h.engine.quickReminders.isEmpty)
    }

    @Test func emptyListStillOffersTheAddButton() throws {
        let sut = try page(Quick.harness())
        #expect(sut.findAll(QuickRow.self).isEmpty)
        #expect(throws: Never.self) { try Find.button(sut, holding: "Quick reminder") }
    }

    @Test func addButtonOpensTheQuickAddPopup() throws {
        let h = Quick.harness()
        try Find.button(page(h), holding: "Quick reminder").tap()
        #expect(h.presenter.calls.contains(.showQuickAdd))
    }
}
