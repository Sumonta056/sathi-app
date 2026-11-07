import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Days off card taps")
struct DaysOffCardTapTests {
    private func harness(_ id: HabitID, _ keys: Set<DayKey> = []) -> EngineHarness {
        EngineHarness {
            $0.prefs.enableAll()
            $0.prefs.setDaysOff(id, keys)
        }
    }

    private func card(_ id: HabitID, _ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(DaysOffCard(habit: id), h).inspect()
    }

    @Test(arguments: HabitID.allCases)
    func tappingRemoveOnARowRemovesThatDate(_ id: HabitID) throws {
        let h = harness(id, [key(2026, 3, 10), key(2026, 3, 12)])
        let label = "Remove \(DaysOffRow.label(key(2026, 3, 10)))"
        try Find.button(card(id, h), label: label).tap()
        #expect(h.store.prefs.days(id).daysOff == [key(2026, 3, 12)])
    }

    @Test(arguments: HabitID.allCases)
    func pickADateChipIsAButtonWithThatLabel(_ id: HabitID) throws {
        let b = try card(id, harness(id)).find(button: "Pick a date")
        #expect(try !b.isDisabled())
    }
}
