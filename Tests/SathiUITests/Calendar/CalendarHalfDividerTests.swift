import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Calendar half dividers")
struct CalendarHalfDividerTests {
    @Test func dayHasASolidLineAtTheEndOfActualAndADashedLineAtTheStartOfPlan() {
        let halves = CalendarSplitGeometry.halves(column: 600, kind: .day)
        let lines = CalendarSplitLines.halfDividers(kind: .day, column: 600, columns: 1)
        #expect(lines.solid == [halves.actualWidth])
        #expect(lines.dashed == [halves.planX])
        #expect(halves.planX - halves.actualWidth == UIMetrics.calendarDayLinkGutter)
    }

    @Test func weekKeepsOneDashedLineAtTheStartOfEachPlanHalf() {
        let planX = CalendarSplitGeometry.halves(column: 200, kind: .week).planX
        let lines = CalendarSplitLines.halfDividers(kind: .week, column: 200, columns: 3)
        #expect(lines.solid.isEmpty)
        #expect(lines.dashed == [planX, 200 + planX, 400 + planX])
    }

    @Test func monthHasNoHalfDividers() {
        let lines = CalendarSplitLines.halfDividers(kind: .month, column: 200, columns: 7)
        #expect(lines.solid.isEmpty)
        #expect(lines.dashed.isEmpty)
    }
}
