import AppKit
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Panel size")
struct PanelSizeTests {
    private func controller(_ h: EngineHarness) -> UIController {
        let ui = UIController()
        ui.engine = h.engine
        return ui
    }

    @Test(arguments: [HabitID.water, .reading, .meditation])
    func bubblePanelHasARealSize(_ id: HabitID) throws {
        let h = EngineHarness()
        let ui = controller(h)
        ui.showBubble(id, .nudge)
        let size = try #require(ui.bubbles[id]).frame.size
        ui.closeBubble(id)
        #expect(size.width > 0)
        #expect(size.height > 0)
    }

    @Test func snoozedNoteHasARealSize() throws {
        let h = EngineHarness()
        let ui = controller(h)
        ui.showSnoozed(.water, until: h.clock.now)
        let size = try #require(ui.note).frame.size
        ui.closeNote()
        #expect(size.width > 0)
        #expect(size.height > 0)
    }

    @Test func daySummaryPanelHasARealSize() throws {
        let h = EngineHarness()
        let ui = controller(h)
        ui.showDaySummary()
        let size = try #require(ui.daySummaryPanel).frame.size
        ui.closeDaySummary()
        #expect(size.width > 0)
        #expect(size.height > 0)
        #expect(ui.daySummaryPanel == nil)
    }

    private func menuHeight(_ items: Int, block: TimeBlockLength? = nil) -> CGFloat {
        let h = Quick.harness(Quick.many(items))
        if let block { h.startBlock("Plan", block) }
        return MenuSize.smallest(MenuPanel(), h)
    }

    @Test func menuHeightIsBoundedByTheVisibleRows() {
        let none = menuHeight(0)
        let four = menuHeight(UIMetrics.quickVisibleRows)
        let full = menuHeight(Limits.quickMax)
        #expect(none > 0)
        #expect(four > none)
        #expect(full == four)
        #expect(full < UIMetrics.menuMaxHeight)
    }

    @Test(arguments: [TimeBlockLength.minutes(30), .open])
    func menuWithARunningBlockStaysUnderTheBound(_ length: TimeBlockLength) {
        let full = menuHeight(Limits.quickMax, block: length)
        #expect(full > 0)
        #expect(full < UIMetrics.menuMaxHeight)
    }

    @Test(arguments: [0, UIMetrics.quickVisibleRows, Limits.quickMax])
    func menuWindowTakesItsNaturalHeight(_ items: Int) {
        let h = Quick.harness(Quick.many(items))
        #expect(MenuSize.smallest(MenuPanel(), h) == MenuSize.ideal(MenuPanel(), h))
    }
}
