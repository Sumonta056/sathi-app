import Foundation
@testable import SathiCore
import Testing

@Suite("CalendarBlockLayout real week")
struct CalendarBlockLayoutRealWeekTests {
    private let minimum: Double = 26

    private func problems(_ rows: [RealWeek.Row], _ plans: [RealWeek.Plan] = []) -> [String] {
        let placed = CalendarBlockLayout.place(RealWeek.blocks(rows, plans), within: RealWeek.column, minimumMinutes: minimum)
        return OverlapCheck.problems(placed, minimumMinutes: minimum)
    }

    @Test func sundayHasNoCoveredBlock() {
        #expect(problems(RealWeek.sun) == [])
    }

    @Test func mondayHasNoCoveredBlock() {
        #expect(problems(RealWeek.mon, RealWeek.monPlans) == [])
    }

    @Test func wednesdayHasNoCoveredBlock() {
        #expect(problems(RealWeek.wed, RealWeek.wedPlans) == [])
    }
}
