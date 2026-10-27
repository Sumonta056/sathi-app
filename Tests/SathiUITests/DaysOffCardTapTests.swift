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
    func tappingAddWithNoPickSavesTodayForThatBuddy(_ id: HabitID) throws {
        let h = harness(id)
        try card(id, h).find(button: "Add").tap()
        #expect(h.store.prefs.days(id).daysOff == [key(2026, 3, 4)])
        for other in HabitID.allCases where other != id {
            #expect(h.store.prefs.days(other).daysOff.isEmpty)
        }
    }

    @Test(arguments: HabitID.allCases)
    func addAfterMidnightSavesTheNewToday(_ id: HabitID) throws {
        let h = harness(id)
        let sut = try card(id, h)
        h.advance(minutes: 15 * 60)
        try sut.find(button: "Add").tap()
        #expect(h.store.prefs.days(id).daysOff == [key(2026, 3, 5)])
    }

    @Test(arguments: HabitID.allCases)
    func tappingRemoveOnARowRemovesThatDate(_ id: HabitID) throws {
        let h = harness(id, [key(2026, 3, 10), key(2026, 3, 12)])
        let label = "Remove \(DaysOffRow.label(key(2026, 3, 10)))"
        try Find.button(card(id, h), label: label).tap()
        #expect(h.store.prefs.days(id).daysOff == [key(2026, 3, 12)])
    }

    @Test(arguments: HabitID.allCases)
    func pickerHasAnAccessibleLabel(_ id: HabitID) throws {
        let picker = try card(id, harness(id)).find(ViewType.DatePicker.self)
        #expect(try picker.labelView().text().string() == "Day off")
    }
}
