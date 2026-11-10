import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Tracker menu and settings wiring")
struct TrackerMenuWiringTests {
    private func draft() -> ActivityDraft {
        ActivityDraft(text: "Code review", category: "Coding", length: .minutes(30), askOffsetMinutes: 0, quiet: false)
    }

    @Test func menuShowsLogActivityWhenTheTrackerIsOn() throws {
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 10))
        let sut = try MenuCards().environmentObject(h.engine).inspect()
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "menu.tracker.log") }
        try sut.find(viewWithAccessibilityIdentifier: "menu.tracker.log").button().tap()
        #expect(h.engine.trackerPrompt?.kind == .center)
    }

    @Test func menuHidesLogActivityWhenTheTrackerIsOff() throws {
        let sut = try MenuCards().environmentObject(EngineHarness().engine).inspect()
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "menu.tracker.log")) == nil)
    }

    @Test func menuShowsTheRunningActivityWithDone() throws {
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 10))
        h.engine.startActivity(draft())
        let sut = try MenuCards().environmentObject(h.engine).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Code review") }
        try sut.find(viewWithAccessibilityIdentifier: "menu.tracker.done").button().tap()
        #expect(h.engine.trackerPrompt?.kind == .whatNow)
    }

    @Test func settingsSidebarHasTheMyDayGroupWithTheTracker() throws {
        let sut = try SettingsSidebar(tab: Box(SettingsTab.general).binding).environmentObject(EngineHarness().engine).inspect()
        #expect(throws: Never.self) { try sut.find(text: Copywriter.trackerSidebarGroup) }
        #expect(throws: Never.self) { try sut.find(text: Copywriter.trackerSettingsTitle) }
    }

    @Test func settingsShowsTheTrackerPage() throws {
        let sut = try SettingsView(tab: .tracker).environmentObject(EngineHarness().engine).inspect()
        #expect(throws: Never.self) { try sut.find(TrackerSettingsPage.self) }
    }
}
