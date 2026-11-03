import AppKit
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Menu panel height")
struct MenuPanelHeightTests {
    private func harness() -> EngineHarness {
        EngineHarness {
            $0.prefs.water.enabled = true
            $0.prefs.reading.enabled = true
        }
    }

    private var chrome: some View {
        VStack(alignment: .leading, spacing: UIMetrics.menuSpacing) {
            MenuHeader()
            PauseChips()
            MenuFooter()
        }
        .padding(UIMetrics.menuPadding)
        .frame(width: UIMetrics.menuWidth)
    }

    private var card: some View {
        HabitCard(id: .water).frame(width: UIMetrics.menuWidth - 2 * UIMetrics.menuPadding)
    }

    @Test func menuWindowShowsTheCards() {
        let h = harness()
        let floor = MenuSize.ideal(chrome, h) + MenuSize.ideal(card, h)
        let smallest = MenuSize.smallest(MenuPanel(), h)
        #expect(smallest > floor)
        #expect(smallest < UIMetrics.menuMaxHeight)
    }

    @Test func menuWindowHeightIsTheNaturalHeight() {
        let h = harness()
        #expect(MenuSize.smallest(MenuPanel(), h) == MenuSize.ideal(MenuPanel(), h))
    }

    @Test func cardsAreaIsCappedAtItsMax() {
        let h = EngineHarness {
            $0.prefs.water.enabled = true
            $0.prefs.reading.enabled = true
            $0.prefs.meditation.enabled = true
            $0.prefs.gym.enabled = true
            $0.live.quickReminders = Quick.many(Limits.quickMax)
        }
        h.startBlock("Plan", .open)
        let cards = MenuSize.smallest(MenuCards(), h)
        #expect(cards == UIMetrics.menuCardsMaxHeight)
    }
}

@MainActor
enum MenuSize {
    static func ideal(_ view: some View, _ h: EngineHarness) -> CGFloat {
        NSHostingView(rootView: view.environmentObject(h.engine)).fittingSize.height
    }

    static func smallest(_ view: some View, _ h: EngineHarness) -> CGFloat {
        let host = NSHostingController(rootView: view.environmentObject(h.engine))
        return host.sizeThatFits(in: CGSize(width: UIMetrics.menuWidth, height: 0)).height
    }
}
