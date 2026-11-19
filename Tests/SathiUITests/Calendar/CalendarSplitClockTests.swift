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
        Fix.grid(
            [:],
            rows: Fix.rows([
                Fix.Row(start: 0, end: 60, height: 60),
                Fix.Row(start: 60, end: 120, height: 90),
                Fix.Row(start: 120, end: 300, height: 22, fold: true),
                Fix.Row(start: 300, end: 360, height: 60)
            ])
        )
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
        let rows = Fix.rows([
            Fix.Row(start: 0, end: 30, height: 30),
            Fix.Row(start: 30, end: 60, height: 30),
            Fix.Row(start: 60, end: 90, height: 30)
        ])
        #expect(CalendarSplitClock.labels(Fix.grid([:], rows: rows)).map(\.text) == ["6 AM", "7 AM"])
    }

    private func trimmed(now: Date) -> CalendarGridLayout {
        let m = CalendarSplitMetrics.metrics(kind: .week, rowMinutes: 60, narrow: false)
        return CalendarSplitLayout.layout(
            [Fix.activity("work", Fix.at(10), Fix.at(11))], days: [Fix.monday], calendar: Fix.cal, rowMinutes: 60, metrics: m, now: now
        )
    }

    @Test func theFirstScrollFindsNowWhenTheEndRowsAreRemoved() {
        let now = Fix.at(15, 30)
        let grid = trimmed(now: now)
        let range = CalendarPageRange.containing(day: Fix.monday, kind: .day, calendar: Fix.cal)
        let row = CalendarSplitClock.initialRow(grid, range: range, now: now, calendar: Fix.cal)
        #expect(grid.rows.last?.endMinute == 600)
        #expect(grid.rows[row].holds(570))
        #expect(!grid.rows[row].isFold)
    }

    @Test func theNowLineSitsInsideTheTrimmedGrid() {
        let grid = trimmed(now: Fix.at(15, 30))
        let y = grid.y(atMinute: 570)
        #expect(y > grid.rows[grid.rows.count - 1].top)
        #expect(y < grid.height)
    }

    @Test func aClickAtTheBottomOfATrimmedGridIsInTheLastOpenRow() {
        let grid = trimmed(now: Fix.at(15, 30))
        let slot = CalendarSplitClock.slotStart(y: CGFloat(grid.height) - 1, grid: grid, day: Fix.monday, calendar: Fix.cal)
        #expect(slot == Fix.at(15, 45))
    }
}
