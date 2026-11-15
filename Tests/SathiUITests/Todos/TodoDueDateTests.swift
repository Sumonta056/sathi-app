import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todo due date control")
struct TodoDueDateTests {
    private final class Box {
        var date: Date
        var picks = 0
        init(_ date: Date) { self.date = date }
    }

    private func due(_ h: EngineHarness, date: Date) throws -> InspectableView<ViewType.ClassifiedView> {
        let view = TodoEditDue(hasDate: .constant(true), date: .constant(date), minutes: .constant(nil))
        return try hosted(view, h).inspect()
    }

    private func grid(_ h: EngineHarness, _ box: Box) throws -> InspectableView<ViewType.ClassifiedView> {
        let date = Binding(get: { box.date }, set: { box.date = $0 })
        return try hosted(TodoDueCalendar(date: date, offset: .constant(0)) { box.picks += 1 }, h).inspect()
    }

    @Test func theDueRowHasNoSystemStepperDatePicker() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try due(h, date: day(2026, 3, 4))
        #expect((try? sut.find(ViewType.DatePicker.self)) == nil)
    }

    @Test func theDueRowShowsTheSharedDateChipWithThePickedDay() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try due(h, date: day(2026, 3, 6))
        let chip = try sut.find(viewWithAccessibilityIdentifier: "todos.edit.date")
        #expect(throws: Never.self) { try chip.find(text: "Fri 6 Mar") }
        #expect(throws: Never.self) { try sut.find(TodoDueDateChip.self) }
    }

    @Test func theDueGridIsTheSharedMonthGrid() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try grid(h, Box(day(2026, 3, 6)))
        #expect(throws: Never.self) { try sut.find(MonthDayGrid.self) }
        #expect(throws: Never.self) { try sut.find(text: "March 2026") }
    }

    @Test func thePickedDayIsMarked() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try grid(h, Box(day(2026, 3, 6)))
        let cell = try sut.find(viewWithAccessibilityLabel: DaysOffRow.label(key(2026, 3, 6)))
        #expect(try cell.accessibilityValue().string() == "Due date")
    }

    @Test func aTapOnADayWritesThatDayAndCloses() async throws {
        let h = await EngineHarness.pageFixture()
        let box = Box(day(2026, 3, 6))
        try Find.button(grid(h, box), label: DaysOffRow.label(key(2026, 3, 12))).tap()
        #expect(box.date == day(2026, 3, 12))
        #expect(box.picks == 1)
    }

    @Test func aPastDayCanBePicked() async throws {
        let h = await EngineHarness.pageFixture()
        let box = Box(day(2026, 3, 6))
        try Find.button(grid(h, box), label: DaysOffRow.label(key(2026, 3, 1))).tap()
        #expect(box.date == day(2026, 3, 1))
    }
}
