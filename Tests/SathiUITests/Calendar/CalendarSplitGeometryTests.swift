import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Calendar split geometry")
struct CalendarSplitGeometryTests {
    typealias Fix = CalendarSplitViewFixtures

    @Test func dayHalvesKeepTheLinkGutterBetweenActualAndPlan() {
        let h = CalendarSplitGeometry.halves(column: 526, kind: .day)
        #expect(h.actualX == 0)
        #expect(h.actualWidth == 300)
        #expect(h.planX == 326)
        #expect(h.planWidth == 200)
    }

    @Test func weekHalvesSplitSixtyFortyWithNoGutter() {
        let h = CalendarSplitGeometry.halves(column: 300, kind: .week)
        #expect(h.actualX == 0)
        #expect(h.actualWidth == 180)
        #expect(h.planX == 180)
        #expect(h.planWidth == 120)
    }

    @Test func aFullWidthBlockFillsItsHalfAtItsTopAndBottom() {
        let halves = CalendarSplitGeometry.halves(column: 300, kind: .week)
        let laid = Fix.laid(Fix.event("Scrum", Fix.at(10), Fix.at(11)), top: 240, bottom: 300)
        let r = CalendarSplitGeometry.rect(laid, halves: halves)
        #expect(r.minX == 180)
        #expect(r.minY == 240)
        #expect(r.height == 60)
        #expect(r.width == 120 - UIMetrics.calendarLaneGap)
    }

    @Test func theSecondLaneStartsHalfWayIntoTheHalf() {
        let halves = CalendarSplitGeometry.halves(column: 300, kind: .week)
        let laid = Fix.laid(Fix.activity("B", Fix.at(10), Fix.at(11)), top: 0, bottom: 60, lane: 1, lanes: 2)
        let r = CalendarSplitGeometry.rect(laid, halves: halves)
        #expect(r.minX == 90)
        #expect(r.width == 90 - UIMetrics.calendarLaneGap)
    }

    @Test(arguments: [1, 2])
    func aRaisedBlockMovesRightByTheCascadeIndentPerDepth(_ depth: Int) {
        let halves = CalendarSplitGeometry.halves(column: 300, kind: .week)
        let laid = Fix.laid(Fix.activity("B", Fix.at(10), Fix.at(11)), top: 0, bottom: 60, depth: depth)
        let r = CalendarSplitGeometry.rect(laid, halves: halves)
        let indent = CGFloat(depth) * UIMetrics.calendarCascadeIndent
        #expect(r.minX == indent)
        #expect(r.width == 180 - indent - UIMetrics.calendarLaneGap)
    }

    @Test func aRaisedSecondLaneUsesTheIndentedWidth() {
        let halves = CalendarSplitGeometry.halves(column: 300, kind: .week)
        let laid = Fix.laid(Fix.event("B", Fix.at(10), Fix.at(11)), top: 0, bottom: 60, lane: 1, lanes: 2, depth: 1)
        let r = CalendarSplitGeometry.rect(laid, halves: halves)
        let indent = UIMetrics.calendarCascadeIndent
        #expect(r.minX == 180 + indent + (120 - indent) / 2)
    }

    @Test func theTodoPillSitsInThePlanHalfAtTheLaidTop() {
        let halves = CalendarSplitGeometry.halves(column: 526, kind: .day)
        var laid = Fix.laid(Fix.todo("Call Rina", Fix.at(15)), top: 540, bottom: 540)
        laid.half = .plan
        let r = CalendarSplitGeometry.todoRect(laid, halves: halves)
        #expect(r.minX >= halves.planX)
        #expect(r.maxX == halves.planX + halves.planWidth)
        #expect(r.midY == 540)
        #expect(r.height == UIMetrics.calendarTodoPillHeight)
    }

    @Test(arguments: [(190.0, true), (200.0, false), (400.0, false)])
    func weekIsNarrowBelowOneHundredTwentyPointsOfActual(_ column: Double, _ narrow: Bool) {
        #expect(CalendarSplitMetrics.isNarrow(column: column, kind: .week) == narrow)
    }

    @Test func dayIsNeverNarrow() {
        #expect(!CalendarSplitMetrics.isNarrow(column: 100, kind: .day))
    }

    @Test func narrowWeekAsksTheEngineForTheNarrowMinimum() {
        #expect(CalendarSplitMetrics.metrics(kind: .week, rowMinutes: 60, narrow: true).minHeight == 22)
        #expect(CalendarSplitMetrics.metrics(kind: .week, rowMinutes: 60, narrow: false).minHeight == 34)
    }
}
