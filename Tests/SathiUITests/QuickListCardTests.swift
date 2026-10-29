import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Quick list card")
struct QuickListCardTests {
    private func card(_ h: EngineHarness, adding: Bool = false) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(QuickListCard(adding: adding), h).inspect()
    }

    @Test func emptyCardShowsOnlyAddRow() throws {
        let sut = try card(Quick.harness())
        #expect(throws: Never.self) { try sut.find(text: "Quick reminder") }
        #expect(throws: Never.self) { try sut.find(text: "Quick reminders") }
        #expect(!MenuFind.hasText(sut, containing: " of 20"))
        #expect(sut.findAll(QuickRow.self).isEmpty)
    }

    @Test func rowsShowTextTimeAndWhen() throws {
        let h = Quick.harness([Quick.item("Call mom", minutes: 25), Quick.item("Invoice", minutes: 175)])
        let sut = try card(h)
        #expect(throws: Never.self) { try sut.find(text: "2 of 20") }
        #expect(sut.findAll(QuickRow.self).count == 2)
        #expect(throws: Never.self) { try sut.find(text: "Call mom") }
        #expect(throws: Never.self) { try sut.find(text: Quick.clock(day(2026, 3, 4, 10, 25))) }
        #expect(throws: Never.self) { try sut.find(text: "in 25m") }
        #expect(throws: Never.self) { try sut.find(text: "in 2h 55m") }
    }

    @Test func rowForTomorrowSaysTomorrow() throws {
        let sut = try card(Quick.harness([Quick.item("Later", minutes: 24 * 60)]))
        #expect(throws: Never.self) { try sut.find(text: "Tomorrow") }
    }

    @Test func rowShowingNowSaysShowingNow() throws {
        let h = Quick.harness([Quick.item("Now", minutes: 0)])
        h.engine.tick()
        let sut = try card(h)
        #expect(throws: Never.self) { try sut.find(text: "Showing now") }
    }

    @Test func deleteButtonRemoves() throws {
        let h = Quick.harness([Quick.item("Call mom", minutes: 25)])
        try card(h).find(viewWithAccessibilityLabel: "Delete this reminder").button().tap()
        #expect(h.engine.quickReminders.isEmpty)
    }

    @Test func rowsScrollOnlyAboveTheVisibleLimit() throws {
        let few = try card(Quick.harness(Quick.many(UIMetrics.quickVisibleRows)))
        #expect(few.findAll(ViewType.ScrollView.self).isEmpty)
        let more = try card(Quick.harness(Quick.many(UIMetrics.quickVisibleRows + 1)))
        #expect(more.findAll(ViewType.ScrollView.self).count == 1)
    }

    @Test func addRowOpensTheFormInsteadOfShowingItself() throws {
        let sut = try card(Quick.harness(), adding: true)
        #expect(throws: Never.self) { try sut.find(text: "New quick reminder") }
    }

    @Test func breakHintOnlyWithItems() throws {
        let hint = "Quick reminders still show during a break."
        let empty = try hosted(MenuPanel(), Quick.harness()).inspect()
        #expect(!MenuFind.hasText(empty, containing: hint))
        let some = try hosted(MenuPanel(), Quick.harness([Quick.item("A", minutes: 5)])).inspect()
        #expect(MenuFind.hasText(some, containing: hint))
    }

    @Test func panelShowsTheCard() throws {
        let sut = try hosted(MenuPanel(), Quick.harness()).inspect()
        #expect(sut.findAll(QuickListCard.self).count == 1)
    }
}
