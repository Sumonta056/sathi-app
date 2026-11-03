import AppKit
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Time block settings sidebar")
struct TimeBlockSettingsSidebarTests {
    private func sidebar(_ h: EngineHarness, _ tab: Box<SettingsTab> = Box(.general)) -> some View {
        SettingsSidebar(tab: tab.binding).environmentObject(h.engine)
    }

    @Test func listsTimeBlocksAfterTheBuddies() throws {
        let sut = try sidebar(EngineHarness()).inspect()
        let order = BlockSettings.texts(sut)
        let gym = try #require(order.firstIndex(of: "Gym"))
        let blocks = try #require(order.firstIndex(of: "Time blocks"))
        let add = try #require(order.firstIndex(of: "Add a buddy"))
        #expect(gym < blocks)
        #expect(blocks < add)
    }

    @Test func timeBlocksNavSelectsTheTimeBlocksTab() throws {
        let tab = Box<SettingsTab>(.general)
        try Find.button(sidebar(EngineHarness(), tab).inspect(), holding: "Time blocks").tap()
        #expect(tab.value == .timeBlocks)
    }

    @Test func selectedTimeBlocksButtonHasTheSelectedTrait() throws {
        let sut = try sidebar(EngineHarness(), Box(.timeBlocks)).inspect()
        #expect(try A11y.isSelected(Find.button(sut, holding: "Time blocks")))
        #expect(try !A11y.isSelected(Find.button(sut, holding: "General")))
    }

    @Test func timeBlocksRowHasNoBuddySwitch() throws {
        let sut = try sidebar(EngineHarness()).inspect()
        #expect(throws: (any Error).self) { try Find.button(sut, label: "Time blocks reminders") }
    }

    @Test func settingsViewShowsThePageForTheTimeBlocksTab() throws {
        let sut = try hosted(SettingsView(tab: .timeBlocks), EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(TimeBlockSettingsPage.self) }
        #expect(Find.lacks(sut, text: "Hi there"))
    }

    @Test func otherTabsDoNotShowThePage() throws {
        let sut = try hosted(SettingsView(), EngineHarness()).inspect()
        #expect(sut.findAll(TimeBlockSettingsPage.self).isEmpty)
    }

    @Test func everyRowStillFitsTheSidebarOnOneLine() {
        let host = NSHostingView(rootView: sidebar(EngineHarness { $0.prefs.meditation.enabled = true }))
        #expect(host.fittingSize.width <= UIMetrics.sidebarWidth)
    }
}
