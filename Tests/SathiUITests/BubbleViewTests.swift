import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Bubble")
struct BubbleViewTests {
    @Test func readingKeepsTheLegacyBubble() throws {
        let h = EngineHarness()
        h.showReminder(.reading)
        let sut = BubbleView(id: .reading, level: .nudge).environmentObject(h.engine)
        #expect(try sut.inspect().find(LegacyBubble.self) != nil)
        #expect(throws: (any Error).self) { try sut.inspect().find(WaterBubble.self) }
    }

    @Test func readingBubbleStartsTheTimer() throws {
        let h = EngineHarness()
        h.showReminder(.reading)
        let sut = BubbleView(id: .reading, level: .nudge).environmentObject(h.engine)
        #expect(try sut.inspect().find(text: "15-minute session") != nil)
        try sut.inspect().find(button: "Start 15-min timer").tap()
        #expect(h.engine.phase == .session(.reading))
    }
}
