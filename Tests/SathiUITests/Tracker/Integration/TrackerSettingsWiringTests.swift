import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Tracker settings wiring")
struct TrackerSettingsWiringTests {
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
