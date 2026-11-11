import AppKit
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Quick panel height")
struct QuickPanelHeightTests {
    private func smallest(_ h: EngineHarness) -> CGFloat { MenuSize.smallest(MenuPanel(), h) }

    private func ideal(_ h: EngineHarness) -> CGFloat { MenuSize.ideal(MenuPanel(), h) }

    @Test func idlePanelIsShorterThanItsMax() {
        #expect(smallest(Glance.harness()) < UIMetrics.menuMaxHeight)
    }

    @Test func panelHeightIsTheNaturalHeight() {
        let h = Glance.harness()
        #expect(smallest(h) == ideal(h))
    }

    @Test func fullPanelHeightIsRigid() {
        let h = Glance.harness(reminders: 5, block: .minutes(30))
        #expect(smallest(h) == ideal(h))
        #expect(smallest(h) < UIMetrics.menuMaxHeight)
    }
}

@MainActor
enum MenuSize {
    static func ideal(_ view: some View, _ h: EngineHarness) -> CGFloat {
        NSHostingView(rootView: view.environmentObject(h.engine)).fittingSize.height
    }

    static func smallest(_ view: some View, _ h: EngineHarness) -> CGFloat {
        let host = NSHostingController(rootView: view.environmentObject(h.engine))
        return host.sizeThatFits(in: CGSize(width: UIMetrics.quickPanelWidth, height: 0)).height
    }
}
