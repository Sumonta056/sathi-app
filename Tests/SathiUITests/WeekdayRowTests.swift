import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Weekday row")
struct WeekdayRowTests {
    private func harness(_ id: HabitID, _ days: Set<Weekday>) -> EngineHarness {
        EngineHarness {
            $0.prefs.enableAll()
            for other in HabitID.allCases {
                $0.prefs.setWeekdays(other, [.monday, .wednesday])
            }
            $0.prefs.setWeekdays(id, days)
        }
    }

    private func row(_ id: HabitID, _ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(WeekdayRow(habit: id), h).inspect()
    }

    @Test(arguments: HabitID.allCases)
    func everyTabShowsAWeekdayRow(_ id: HabitID) throws {
        let h = harness(id, [.monday, .wednesday])
        let sut = try settingsTab(id, h)
        #expect(throws: Never.self) { try sut.find(WeekdayRow.self) }
        try Find.button(sut, label: "Friday").tap()
        #expect(h.store.prefs.days(id).weekdays == [.monday, .wednesday, .friday])
        for other in HabitID.allCases where other != id {
            #expect(h.store.prefs.days(other).weekdays == [.monday, .wednesday])
        }
    }

    @Test(arguments: HabitID.allCases)
    func rowShowsSevenDaysWithTheSelectedOnesMarked(_ id: HabitID) throws {
        let sut = try row(id, harness(id, [.tuesday, .saturday]))
        for weekday in Weekday.allCases {
            let chip = try Find.button(sut, label: weekday.name)
            #expect(A11y.isSelected(chip) == [.tuesday, .saturday].contains(weekday))
        }
    }

    @Test(arguments: HabitID.allCases)
    func tappingASelectedDayTurnsItOff(_ id: HabitID) throws {
        let h = harness(id, [.tuesday, .saturday])
        try Find.button(row(id, h), label: "Saturday").tap()
        #expect(h.store.prefs.days(id).weekdays == [.tuesday])
    }

    @Test(arguments: HabitID.allCases)
    func lastWeekdayCannotBeTurnedOff(_ id: HabitID) throws {
        let h = harness(id, [.thursday])
        try Find.button(row(id, h), label: "Thursday").tap()
        #expect(h.engine.data.prefs.days(id).weekdays == [.thursday])
    }

    @Test(arguments: HabitID.allCases)
    func weekdaysBindingReadsAndSavesThatBuddyOnly(_ id: HabitID) {
        let h = harness(id, [.sunday])
        #expect(h.engine.weekdays(id).wrappedValue == [.sunday])
        h.engine.weekdays(id).wrappedValue = [.sunday, .monday]
        #expect(h.store.prefs.days(id).weekdays == [.sunday, .monday])
        for other in HabitID.allCases where other != id {
            #expect(h.store.prefs.days(other).weekdays == [.monday, .wednesday])
        }
    }
}
