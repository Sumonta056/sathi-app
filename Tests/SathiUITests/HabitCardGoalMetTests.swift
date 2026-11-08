import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Habit card goal met")
struct HabitCardGoalMetTests {
    private func card(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(HabitCard(id: .water), h).inspect()
    }

    private func drink(_ glasses: Int, _ h: EngineHarness) {
        for _ in 0 ..< glasses {
            h.engine.logWater(1)
        }
        h.engine.endCelebrate()
    }

    @Test func goalMetShowsTheCheckBadge() throws {
        let h = EngineHarness()
        drink(8, h)
        #expect(throws: Never.self) { try card(h).find(viewWithAccessibilityLabel: "Goal met") }
    }

    @Test func goalMetShowsTheGoalMetPill() throws {
        let h = EngineHarness()
        drink(8, h)
        #expect(throws: Never.self) { try card(h).find(text: "✓ Goal met") }
    }

    @Test func goalNotMetHasNoCheckBadge() throws {
        let h = EngineHarness()
        drink(7, h)
        #expect(throws: (any Error).self) { try card(h).find(viewWithAccessibilityLabel: "Goal met") }
    }

    @Test func goalMetKeepsTheActionButton() throws {
        let h = EngineHarness()
        drink(8, h)
        try MenuFind.control(card(h), "+1 glass").tap()
        #expect(h.engine.glassesToday == 9)
    }
}
