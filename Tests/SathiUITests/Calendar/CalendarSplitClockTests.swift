import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Calendar split clock")
struct CalendarSplitClockTests {
    typealias Fix = CalendarSplitViewFixtures

    private var grown: CalendarGridLayout {
        Fix.grid([:], rows: Fix.rows([(0, 60, 60, false), (60, 120, 90, false), (120, 300, 22, true), (300, 360, 60, false)]))
    }

    @Test func minuteCountsFromSixAM() {
        #expect(CalendarSplitClock.minute(Fix.at(7, 40), day: Fix.monday, calendar: Fix.cal) == 100)
        #expect(CalendarSplitClock.minute(Fix.at(5), day: Fix.monday, calendar: Fix.cal) == 0)
    }

    @Test func minuteAfterMidnightBelongsToTheSamePageDay() {
        let late = Fix.z.date(2026, 11, 17, 1, 30)
        #expect(CalendarSplitClock.minute(late, day: Fix.monday, calendar: Fix.cal) == 1170)
    }

    @Test func aSlotClickRoundsDownToFifteenMinutes() {
        let slot = CalendarSplitClock.slotStart(y: 100, grid: grown, day: Fix.monday, calendar: Fix.cal)
        #expect(slot == Fix.at(7, 30))
    }

    @Test func aClickInTheGrownEndOfARowStaysInThatRow() {
        let slot = CalendarSplitClock.slotStart(y: 145, grid: grown, day: Fix.monday, calendar: Fix.cal)
        #expect(slot == Fix.at(7, 45))
    }

    @Test func aClickInTheFirstRowGivesItsQuarter() {
        let slot = CalendarSplitClock.slotStart(y: 59, grid: grown, day: Fix.monday, calendar: Fix.cal)
        #expect(slot == Fix.at(6, 45))
    }

    @Test func initialRowIsTheRowThatHoldsNow() {
        let range = Fix.dayRange()
        #expect(CalendarSplitClock.initialRow(grown, range: range, now: Fix.at(11, 20), calendar: Fix.cal) == 3)
        #expect(CalendarSplitClock.initialRow(grown, range: range, now: Fix.at(7, 10), calendar: Fix.cal) == 1)
    }

    @Test func initialRowIsSixAMForAnotherRange() {
        let range = Fix.dayRange()
        let later = Fix.z.date(2026, 11, 25, 11)
        #expect(CalendarSplitClock.initialRow(grown, range: range, now: later, calendar: Fix.cal) == 0)
    }

    @Test func marksDrawAnHourLineAndDashedQuartersInsideOpenRowsOnly() {
        let marks = CalendarSplitClock.marks(grown)
        #expect(marks.filter(\.isHour).map(\.y) == [0, 60, 172])
        #expect(marks.filter { !$0.isHour }.map(\.y) == [15, 30, 45, 75, 90, 105, 187, 202, 217])
    }

    @Test func labelsShowEachHourRowAndSkipFolds() {
        let labels = CalendarSplitClock.labels(grown)
        #expect(labels.map(\.text) == ["6 AM", "7 AM", "11 AM"])
        #expect(labels.map(\.row) == [0, 1, 3])
    }

    @Test func zoomedRowsLabelOnlyTheHour() {
        let rows = Fix.rows([(0, 30, 30, false), (30, 60, 30, false), (60, 90, 30, false)])
        #expect(CalendarSplitClock.labels(Fix.grid([:], rows: rows)).map(\.text) == ["6 AM", "7 AM"])
    }
}
