import AppKit
import SathiCore
import SathiTestSupport
@testable import SathiUI
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
}
