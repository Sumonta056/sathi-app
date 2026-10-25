import AppKit
import SathiCore
import SathiTestSupport
@testable import SathiUI
import Testing

@MainActor
@Suite("Corner stack")
struct CornerStackTests {
    private func controller(_ h: EngineHarness) -> UIController {
        let ui = UIController()
        ui.engine = h.engine
        return ui
    }

    @Test func anotherHabitsBubbleKeepsTheSnoozedNote() {
        let h = EngineHarness()
        let ui = controller(h)
        ui.showSnoozed(.reading, until: h.clock.now)
        ui.showBubble(.water, .nudge)
        #expect(ui.note != nil)
        ui.closeBubble(.water)
        ui.closeNote()
    }

    @Test func panelsStackDownInTheOrderTheyOpen() throws {
        let h = EngineHarness()
        let ui = controller(h)
        ui.showBubble(.water, .nudge)
        ui.showBubble(.meditation, .nudge)
        let water = try #require(ui.bubbles[.water]).frame
        let calm = try #require(ui.bubbles[.meditation]).frame
        #expect(ui.corner.count == 2)
        #expect(calm.maxY < water.maxY)
        ui.closeBubble(.water)
        ui.closeBubble(.meditation)
    }

    @Test func closingAPanelMovesTheNextOneUp() throws {
        let h = EngineHarness()
        let ui = controller(h)
        ui.showBubble(.water, .nudge)
        let top = try #require(ui.bubbles[.water]).frame.maxY
        ui.showBubble(.meditation, .nudge)
        ui.closeBubble(.water)
        #expect(ui.corner.count == 1)
        #expect(try #require(ui.bubbles[.meditation]).frame.maxY == top)
        ui.closeBubble(.meditation)
        #expect(ui.corner.isEmpty)
        #expect(ui.cornerScreen == nil)
    }
}
