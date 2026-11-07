import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Day off calendar")
struct DayOffCalendarTests {
    private func harness(_ id: HabitID, _ keys: Set<DayKey> = []) -> EngineHarness {
        EngineHarness(at: day(2026, 11, 7, 10)) {
            $0.prefs.enableAll()
            $0.prefs.setDaysOff(id, keys)
        }
    }

    private func spoken(_ d: Int) -> String { DaysOffRow.label(key(2026, 11, d)) }

    private func calendar(_ id: HabitID, _ h: EngineHarness, offset: Int = 0) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(DayOffCalendar(habit: id, accent: Night.accent(id), offset: .constant(offset)), h).inspect()
    }

    @Test(arguments: HabitID.allCases)
    func tappingTodayAddsIt(_ id: HabitID) throws {
        let h = harness(id)
        try Find.button(calendar(id, h), label: spoken(7)).tap()
        #expect(h.store.prefs.days(id).daysOff == [key(2026, 11, 7)])
        for other in HabitID.allCases where other != id {
            #expect(h.store.prefs.days(other).daysOff.isEmpty)
        }
    }

    @Test(arguments: HabitID.allCases)
    func aPastDayIsDisabled(_ id: HabitID) throws {
        let sut = try calendar(id, harness(id))
        #expect(try Find.button(sut, label: spoken(6)).isDisabled())
        #expect(try !Find.button(sut, label: spoken(8)).isDisabled())
    }

    @Test(arguments: HabitID.allCases)
    func aDayOffIsMarkedAndDisabled(_ id: HabitID) throws {
        let sut = try calendar(id, harness(id, [key(2026, 11, 12)]))
        let cell = try sut.find(viewWithAccessibilityLabel: spoken(12))
        #expect(try cell.accessibilityValue().string() == "Day off")
        #expect(try Find.button(sut, label: spoken(12)).isDisabled())
    }

    @Test(arguments: HabitID.allCases)
    func theBackArrowIsDisabledAtTheFirstMonth(_ id: HabitID) throws {
        let sut = try calendar(id, harness(id))
        #expect(try Find.button(sut, label: "Previous month").isDisabled())
        #expect(try !Find.button(sut, label: "Next month").isDisabled())
    }

    @Test(arguments: HabitID.allCases)
    func theTitleNamesTheMonth(_ id: HabitID) throws {
        let sut = try calendar(id, harness(id))
        #expect(throws: Never.self) { try sut.find(text: "November 2026") }
    }

    @Test(arguments: HabitID.allCases)
    func theLastMonthDisablesTheForwardArrow(_ id: HabitID) throws {
        let sut = try calendar(id, harness(id), offset: 12)
        #expect(try Find.button(sut, label: "Next month").isDisabled())
        #expect(try !Find.button(sut, label: "Previous month").isDisabled())
    }

    @Test(arguments: HabitID.allCases)
    func aPickKeepsTheMonthAndMarksTheDay(_ id: HabitID) throws {
        let h = harness(id)
        var shown = 1
        let offset = Binding(get: { shown }, set: { shown = $0 })
        let view = { try hosted(DayOffCalendar(habit: id, accent: Night.accent(id), offset: offset), h).inspect() }
        let dec4 = DaysOffRow.label(key(2026, 12, 4))
        try Find.button(view(), label: dec4).tap()
        #expect(shown == 1)
        #expect(h.store.prefs.days(id).daysOff == [key(2026, 12, 4)])
        let after = try view()
        #expect(throws: Never.self) { try after.find(text: "December 2026") }
        #expect(try after.find(viewWithAccessibilityLabel: dec4).accessibilityValue().string() == "Day off")
        #expect(try Find.button(after, label: dec4).isDisabled())
        try Find.button(after, label: DaysOffRow.label(key(2026, 12, 5))).tap()
        #expect(h.store.prefs.days(id).daysOff == [key(2026, 12, 4), key(2026, 12, 5)])
    }
}
