import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Tracker settings wiring")
struct TrackerSettingsWiringTests {
    @Test func settingsShowsTheTrackerPage() throws {
        let sut = try SettingsPageView(page: .tracker).environmentObject(EngineHarness().engine).inspect()
        #expect(throws: Never.self) { try sut.find(TrackerSettingsPage.self) }
    }
}
