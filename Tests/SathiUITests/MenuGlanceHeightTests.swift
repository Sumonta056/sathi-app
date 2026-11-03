import AppKit
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Menu glance height")
struct MenuGlanceHeightTests {
    private func tallest(_ h: EngineHarness) -> CGFloat {
        let host = NSHostingController(rootView: MenuPanel().environmentObject(h.engine))
        return host.sizeThatFits(in: CGSize(width: UIMetrics.menuWidth, height: 100_000)).height
    }

    @Test func idleFourBuddyPanelIsShorterThanFiveHundred() {
        #expect(MenuSize.smallest(MenuPanel(), Glance.harness()) < 500)
    }

    @Test func idlePanelHeightIsRigid() {
        let h = Glance.harness()
        #expect(tallest(h) == MenuSize.smallest(MenuPanel(), h))
    }

    @Test func fullPanelHeightIsRigid() {
        let h = Glance.harness(reminders: 5, block: .minutes(30))
        #expect(tallest(h) == MenuSize.smallest(MenuPanel(), h))
    }
}
