import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Days off card")
struct DaysOffCardTests {
    private func harness(_ id: HabitID, _ keys: Set<DayKey> = []) -> EngineHarness {
        EngineHarness {
            $0.prefs.enableAll()
            $0.prefs.setDaysOff(id, keys)
        }
    }

    private func card(_ id: HabitID, _ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(DaysOffCard(habit: id), h).inspect()
    }

    private func hint(_ id: HabitID) -> String {
        "\(id.buddy) stays quiet on these days. They never break your streak."
    }

    @Test(arguments: HabitID.allCases)
    func everyTabShowsADaysOffCard(_ id: HabitID) throws {
        let sut = try settingsTab(id, harness(id))
        #expect(throws: Never.self) { try sut.find(DaysOffCard.self) }
        #expect(throws: Never.self) { try sut.find(text: "DAYS OFF") }
        #expect(throws: Never.self) { try sut.find(text: hint(id)) }
    }

    @Test(arguments: HabitID.allCases)
    func cardHasAPickADateChipAndNoStepperOrAddButton(_ id: HabitID) throws {
        let sut = try card(id, harness(id))
        #expect(throws: Never.self) { try sut.find(button: "Pick a date") }
        #expect((try? sut.find(ViewType.DatePicker.self)) == nil)
        #expect((try? sut.find(button: "Add")) == nil)
    }

    @Test(arguments: HabitID.allCases)
    func emptyListShowsTheEmptyLine(_ id: HabitID) throws {
        let sut = try card(id, harness(id))
        #expect(throws: Never.self) { try sut.find(text: "No days off planned.") }
    }

    @Test(arguments: HabitID.allCases)
    func onlyPastDatesShowTheEmptyLine(_ id: HabitID) throws {
        let sut = try card(id, harness(id, [key(2026, 2, 1), key(2026, 3, 3)]))
        #expect(throws: Never.self) { try sut.find(text: "No days off planned.") }
    }

    @Test(arguments: HabitID.allCases)
    func eachPlannedDateHasARemoveButtonAndHidesTheEmptyLine(_ id: HabitID) throws {
        let empty = try card(id, harness(id)).findAll(ViewType.Button.self).count
        let sut = try card(id, harness(id, [key(2026, 3, 3), key(2026, 3, 10), key(2026, 5, 1)]))
        #expect(Find.lacks(sut, text: "No days off planned."))
        #expect(sut.findAll(ViewType.Button.self).count == empty + 2)
    }

    @Test(arguments: HabitID.allCases)
    func listedDatesAreTodayAndLaterInOrder(_ id: HabitID) {
        let h = harness(id, [key(2026, 4, 1), key(2026, 3, 3), key(2026, 3, 4), key(2025, 12, 25), key(2026, 3, 10)])
        #expect(h.engine.upcomingDaysOff(id) == [key(2026, 3, 4), key(2026, 3, 10), key(2026, 4, 1)])
    }

    @Test(arguments: HabitID.allCases)
    func addingADateSavesItForThatBuddyOnly(_ id: HabitID) {
        let h = harness(id)
        h.engine.addDayOff(id, day(2026, 3, 10, 15))
        #expect(h.store.prefs.days(id).daysOff == [key(2026, 3, 10)])
        #expect(h.engine.upcomingDaysOff(id) == [key(2026, 3, 10)])
        for other in HabitID.allCases where other != id {
            #expect(h.store.prefs.days(other).daysOff.isEmpty)
        }
    }

    @Test(arguments: HabitID.allCases)
    func todayCanBeAdded(_ id: HabitID) {
        let h = harness(id)
        h.engine.addDayOff(id, day(2026, 3, 4, 8))
        #expect(h.store.prefs.days(id).daysOff == [key(2026, 3, 4)])
    }

    @Test(arguments: HabitID.allCases)
    func pastAndDuplicateDatesAreIgnored(_ id: HabitID) {
        let h = harness(id, [key(2026, 3, 10)])
        h.engine.addDayOff(id, day(2026, 3, 3, 23))
        h.engine.addDayOff(id, day(2026, 3, 10, 9))
        h.engine.addDayOff(id, day(2026, 3, 10, 21))
        #expect(h.engine.data.prefs.days(id).daysOff == [key(2026, 3, 10)])
        h.engine.addDayOff(id, day(2026, 3, 11, 9))
        #expect(h.store.prefs.days(id).daysOff == [key(2026, 3, 10), key(2026, 3, 11)])
    }

    @Test(arguments: HabitID.allCases)
    func aDateMoreThanAYearAheadIsIgnored(_ id: HabitID) {
        let h = harness(id)
        h.engine.addDayOff(id, day(2027, 3, 5, 12))
        #expect(h.engine.data.prefs.days(id).daysOff.isEmpty)
        h.engine.addDayOff(id, day(2027, 3, 4, 12))
        #expect(h.store.prefs.days(id).daysOff == [key(2027, 3, 4)])
    }

    @Test(arguments: HabitID.allCases)
    func aHundredAndFirstFutureDateIsIgnored(_ id: HabitID) {
        let future = Set((5 ..< 5 + Limits.daysOffMax).map { key(2026, 3, $0) })
        let h = harness(id, future)
        h.engine.addDayOff(id, day(2026, 3, 4, 12))
        #expect(h.engine.data.prefs.days(id).daysOff == future)
        h.engine.removeDayOff(id, key(2026, 3, 5))
        h.engine.addDayOff(id, day(2026, 3, 4, 12))
        #expect(h.store.prefs.days(id).daysOff == future.subtracting([key(2026, 3, 5)]).union([key(2026, 3, 4)]))
    }

    @Test(arguments: HabitID.allCases)
    func pastDatesDoNotCountTowardTheLimit(_ id: HabitID) {
        let future = Set((5 ..< 4 + Limits.daysOffMax).map { key(2026, 3, $0) })
        let past = Set((1 ... 10).map { key(2026, 2, $0) })
        let h = harness(id, future.union(past))
        h.engine.addDayOff(id, day(2026, 3, 4, 12))
        #expect(h.store.prefs.days(id).daysOff == future.union(past).union([key(2026, 3, 4)]))
    }

    @Test(arguments: HabitID.allCases)
    func removingADateSavesIt(_ id: HabitID) {
        let h = harness(id, [key(2026, 3, 10), key(2026, 3, 12)])
        h.engine.removeDayOff(id, key(2026, 3, 10))
        #expect(h.store.prefs.days(id).daysOff == [key(2026, 3, 12)])
        #expect(h.engine.upcomingDaysOff(id) == [key(2026, 3, 12)])
    }
}
