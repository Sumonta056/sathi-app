import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Quick panel do now")
struct QuickDoNowTests {
    private func panel(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(MenuPanel(), h).inspect()
    }

    @Test func moveStartsGymFromTheMenu() throws {
        let h = Glance.harness()
        try panel(h).find(viewWithAccessibilityIdentifier: "doNow.gym").button().tap()
        #expect(h.presenter.calls.contains(.showSession(.gym)))
    }

    @Test func noDoNowWhileItsSessionRuns() throws {
        let h = Glance.harness()
        h.engine.startSession(.gym)
        #expect(throws: (any Error).self) { try panel(h).find(viewWithAccessibilityIdentifier: "doNow.gym") }
        #expect(throws: Never.self) { try panel(h).find(viewWithAccessibilityIdentifier: "doNow.reading") }
    }

    @Test func offBuddyHasNoDoNow() throws {
        let h = EngineHarness(at: Quick.now) { $0.prefs.gym.enabled = false }
        #expect(throws: (any Error).self) { try panel(h).find(viewWithAccessibilityIdentifier: "doNow.gym") }
    }
}
