import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Bubble")
struct BubbleViewTests {
    private func waterBubble(_ h: EngineHarness, _ level: Level = .nudge) -> some View {
        BubbleView(id: .water, level: level).environmentObject(h.engine)
    }

    @Test func waterBubbleShowsCopyAndGlassChoices() throws {
        let h = EngineHarness()
        h.showReminder(.water)
        let sut = waterBubble(h)
        #expect(try sut.inspect().find(text: h.engine.copy.title) != nil)
        for label in ["A few sips", "Half", "Full glass"] {
            #expect(try sut.inspect().find(text: label) != nil)
        }
    }

    @Test func tappingHalfLogsHalfAGlass() throws {
        let h = EngineHarness()
        h.showReminder(.water)
        try waterBubble(h).inspect().find(text: "Half").find(ViewType.Button.self, relation: .parent).tap()
        #expect(h.engine.data.drinks.last?.glasses == 0.5)
        #expect(h.engine.phase == .celebrate)
    }

    @Test func snoozeButtonSnoozes() throws {
        let h = EngineHarness()
        h.showReminder(.water)
        try waterBubble(h).inspect().find(button: "Snooze 5 min").tap()
        #expect(h.engine.phase == .idle)
        #expect(h.engine.state(.water).snoozes == 1)
    }

    @Test func persistLevelShowsTheLockWarning() throws {
        let h = EngineHarness()
        h.showReminder(.water)
        h.engine.snooze()
        h.advance(minutes: 5)
        let sut = waterBubble(h, .persist)
        #expect(try sut.inspect().find(text: h.engine.warnText(.water)) != nil)
        #expect(try sut.inspect().find(button: "Last snooze") != nil)
    }

    @Test func nudgeLevelHasNoWarning() throws {
        let h = EngineHarness()
        h.showReminder(.water)
        #expect(throws: (any Error).self) { try waterBubble(h).inspect().find(ViewType.Image.self) { try $0.actualImage().name() == "lock.fill" } }
    }

    @Test func readingBubbleStartsTheTimer() throws {
        let h = EngineHarness()
        h.showReminder(.reading)
        let sut = BubbleView(id: .reading, level: .nudge).environmentObject(h.engine)
        #expect(try sut.inspect().find(text: "15-minute session") != nil)
        try sut.inspect().find(button: "Start 15-min timer").tap()
        #expect(h.engine.phase == .session)
    }
}
