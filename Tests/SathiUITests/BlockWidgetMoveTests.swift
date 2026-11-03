import AppKit
import SathiCore
import SathiTestSupport
@testable import SathiUI
import Testing

@MainActor
@Suite("Block widget move")
struct BlockWidgetMoveTests {
    private func controller(_ h: EngineHarness) -> UIController {
        let ui = UIController()
        ui.engine = h.engine
        return ui
    }

    private func moved(_ origin: NSPoint, by delta: CGSize) -> NSPoint {
        NSPoint(x: origin.x + delta.width, y: origin.y + delta.height)
    }

    @Test func movingShiftsTheWidgetByTheDelta() throws {
        let h = Block.running(.minutes(30), after: 5)
        let ui = controller(h)
        ui.showBlockWidget()
        let start = try #require(ui.blockPanels[.widget]).frame.origin
        ui.moveBlockWidget(by: CGSize(width: -120, height: -80))
        #expect(try #require(ui.blockPanels[.widget]).frame.origin == moved(start, by: CGSize(width: -120, height: -80)))
        ui.closeBlockWidget()
    }

    @Test func aClickWithNoMoveKeepsTheWidgetInTheCorner() throws {
        let h = Block.running(.minutes(30), after: 5)
        let ui = controller(h)
        ui.showBlockWidget()
        let p = try #require(ui.blockPanels[.widget])
        ui.moveBlockWidget(by: .zero)
        #expect(ui.corner.contains { $0 === p })
        ui.closeBlockWidget()
    }

    @Test func movingTwiceAddsUpTheSteps() throws {
        let h = Block.running(.minutes(30), after: 5)
        let ui = controller(h)
        ui.showBlockWidget()
        let start = try #require(ui.blockPanels[.widget]).frame.origin
        ui.moveBlockWidget(by: CGSize(width: -30, height: 10))
        ui.moveBlockWidget(by: CGSize(width: 5, height: -40))
        #expect(try #require(ui.blockPanels[.widget]).frame.origin == moved(start, by: CGSize(width: -25, height: -30)))
        ui.closeBlockWidget()
    }

    @Test func aMovedWidgetLeavesTheCornerStack() throws {
        let h = Block.running(.minutes(30), after: 5)
        let ui = controller(h)
        ui.showBlockWidget()
        let widget = try #require(ui.blockPanels[.widget])
        ui.moveBlockWidget(by: CGSize(width: -50, height: -50))
        #expect(!ui.corner.contains { $0 === widget })
        #expect(ui.corner.isEmpty)
        #expect(ui.cornerScreen == nil)
        ui.closeBlockWidget()
    }

    @Test func otherCornerPanelsDoNotMoveAMovedWidget() throws {
        let h = Block.running(.minutes(30), after: 5)
        let ui = controller(h)
        ui.showBubble(.meditation, .nudge)
        ui.showBlockWidget()
        ui.moveBlockWidget(by: CGSize(width: -200, height: -150))
        let placed = try #require(ui.blockPanels[.widget]).frame.origin
        ui.showBubble(.water, .nudge)
        #expect(try #require(ui.blockPanels[.widget]).frame.origin == placed)
        ui.closeBubble(.meditation)
        #expect(try #require(ui.blockPanels[.widget]).frame.origin == placed)
        ui.showBlockDone()
        #expect(try #require(ui.blockPanels[.widget]).frame.origin == placed)
        ui.closeBubble(.water)
        ui.closeBlockDone()
        #expect(try #require(ui.blockPanels[.widget]).frame.origin == placed)
        ui.closeBlockWidget()
    }

    @Test func aMovedWidgetIsNotStackedWithOtherPanels() throws {
        let h = Block.running(.minutes(30), after: 5)
        let ui = controller(h)
        ui.showBlockWidget()
        let top = try #require(ui.blockPanels[.widget]).frame.maxY
        ui.moveBlockWidget(by: CGSize(width: -200, height: -150))
        ui.showBubble(.water, .nudge)
        #expect(ui.corner.count == 1)
        #expect(try #require(ui.bubbles[.water]).frame.maxY == top)
        ui.closeBubble(.water)
        ui.closeBlockWidget()
    }

    @Test func closingAMovedWidgetHidesAndForgetsIt() throws {
        let h = Block.running(.minutes(30), after: 5)
        let ui = controller(h)
        ui.showBlockWidget()
        let widget = try #require(ui.blockPanels[.widget])
        ui.moveBlockWidget(by: CGSize(width: -60, height: -40))
        ui.closeBlockWidget()
        #expect(!widget.isVisible)
        #expect(ui.blockPanels[.widget] == nil)
        #expect(ui.corner.isEmpty)
        #expect(ui.cornerScreen == nil)
    }

    @Test func aNewWidgetGoesBackToTheCorner() throws {
        let h = Block.running(.minutes(30), after: 5)
        let ui = controller(h)
        ui.showBlockWidget()
        let home = try #require(ui.blockPanels[.widget]).frame.origin
        ui.moveBlockWidget(by: CGSize(width: -300, height: -200))
        ui.closeBlockWidget()
        ui.showBlockWidget()
        let fresh = try #require(ui.blockPanels[.widget])
        #expect(ui.corner.contains { $0 === fresh })
        #expect(fresh.frame.origin == home)
        ui.closeBlockWidget()
    }

    @Test func movingWithNoWidgetDoesNothing() throws {
        let h = Block.running(.minutes(30), after: 5)
        let ui = controller(h)
        ui.showBlockDone()
        let done = try #require(ui.blockPanels[.done])
        let origin = done.frame.origin
        ui.moveBlockWidget(by: CGSize(width: -100, height: -100))
        #expect(ui.blockPanels[.widget] == nil)
        #expect(done.frame.origin == origin)
        #expect(ui.corner.count == 1)
        ui.closeBlockDone()
    }
}
