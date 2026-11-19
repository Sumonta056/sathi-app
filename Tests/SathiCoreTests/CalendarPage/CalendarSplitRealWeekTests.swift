import Foundation
@testable import SathiCore
import Testing

@Suite("Calendar split layout: real week 14 to 20 Nov")
struct CalendarSplitRealWeekTests {
    private let tuesday = 17
    private let wednesday = 18

    private var weekGrid: CalendarGridLayout {
        Split.layout(RealEvents.all, days: RealEvents.days, metrics: Split.week)
    }

    private func dayGrid(_ date: Int) -> CalendarGridLayout {
        Split.layout(RealEvents.all, days: [Split.key(date)], metrics: Split.day)
    }

    @Test(arguments: [1, 2, 4])
    func weekHasNoLayoutProblems(_ rowSteps: Int) {
        let rowMinutes = 60 / rowSteps
        let m = Split.metrics(pointsPerMinute: Double(rowSteps), minHeight: 34, awayMinHeight: 34, gap: 2, folds: true)
        let grid = Split.layout(RealEvents.all, days: RealEvents.days, rowMinutes: rowMinutes, metrics: m)
        #expect(SplitCheck.problems(grid, metrics: m, ppm: Double(rowSteps)) == [])
    }

    @Test func narrowWeekHasNoLayoutProblems() {
        let grid = Split.layout(RealEvents.all, days: RealEvents.days, metrics: Split.weekNarrow)
        #expect(SplitCheck.problems(grid, metrics: Split.weekNarrow) == [])
    }

    @Test(arguments: Array(14 ... 20))
    func dayHasNoLayoutProblems(_ date: Int) {
        #expect(SplitCheck.problems(dayGrid(date), metrics: Split.day) == [])
    }

    @Test func weekShowsEveryDayAndEveryItem() {
        let grid = weekGrid
        #expect(Set(grid.days.keys) == Set(RealEvents.days))
        let placed = grid.days.values.joined().flatMap { [$0] + $0.hidden }.map(\.block.id)
        let visibleIDs = Set(placed)
        let eventIDs = Set(RealEvents.events.map(\.id))
        #expect(eventIDs.isSubset(of: visibleIDs))
    }

    @Test func dayShowsEveryItemOfThatDay() {
        let grid = dayGrid(16)
        let placed = Set((grid.days[Split.key(16)] ?? []).flatMap { [$0] + $0.hidden }.map(\.block.id))
        let monday = Set(RealEvents.all.filter { Split.key(16) == CalendarPageDay.key(holding: $0.interval.start, calendar: Split.calendar) }
            .map(\.id))
        #expect(placed == monday)
    }

    @Test(arguments: [false, true])
    func tuesdayClassKeepsFullWidthAndTheWorkshopIsRaised(_ week: Bool) {
        let grid = week ? weekGrid : dayGrid(tuesday)
        let tue = Split.key(tuesday)
        let course = RealEvents.laid(grid, "Bangladesh Bank AI Professional Class", on: tuesday)
        let workshop = RealEvents.laid(grid, "CCAR-F Exam Preparation Workshop", on: tuesday)
        #expect(course?.depth == 0)
        #expect(course?.lanes == 1)
        #expect(workshop?.depth == 1)
        #expect(workshop?.lanes == 1)
        #expect(course?.top == Split.y(grid, "13:00", on: tue))
        #expect(workshop?.top == Split.y(grid, "17:00", on: tue))
    }

    @Test(arguments: [false, true])
    func wednesdayBriefAndScrumSitSideBySideAtTheirRealTimes(_ week: Bool) {
        let grid = week ? weekGrid : dayGrid(wednesday)
        let wed = Split.key(wednesday)
        let brief = RealEvents.laid(grid, "Friday Java Brief", on: wednesday)
        let scrum = RealEvents.laid(grid, "Frontline Morning Scrum", on: wednesday)
        #expect(brief?.lanes == 2)
        #expect(scrum?.lanes == 2)
        #expect(Set([brief?.lane, scrum?.lane]) == Set([0, 1]))
        #expect(brief?.depth == 0)
        #expect(scrum?.depth == 0)
        #expect(brief?.top == Split.y(grid, "10:06", on: wed))
        #expect(scrum?.top == Split.y(grid, "10:30", on: wed))
    }

    @Test func mondayScrumCopiesWithTheSameStartSitSideBySide() {
        let grid = dayGrid(16)
        let plans = (grid.days[Split.key(16)] ?? []).filter { $0.half == .plan && $0.block.title.hasPrefix("Personal Editorial") }
        #expect(plans.count == 2)
        #expect(plans.allSatisfy { $0.lanes == 2 })
    }

    @Test func mondayTestingRowShowsItsRoundedSpan() {
        let grid = weekGrid
        let testing = grid.days[Split.key(16)]?.first { $0.block.interval.start == Split.at("14:35:54", on: 16) }
        #expect(testing?.span == Split.span("14:36", "15:02", on: 16))
        #expect(testing?.top == Split.y(grid, "14:36", on: Split.key(16)))
    }

    @Test func weekFoldsTheEarlyMorningAndKeepsDaytimeOpen() {
        let grid = weekGrid
        #expect(grid.rows.first?.isFold == false)
        #expect(Split.row(grid, holding: 60)?.isFold == false)
        #expect(Split.row(grid, holding: 7 * 60)?.isFold == false)
        #expect(Split.row(grid, holding: 22 * 60) == nil)
        #expect(grid.rows.last?.isFold == false)
        #expect(grid.rows.last?.endMinute == 17 * 60)
    }

    @Test func noRowEverShrinks() {
        let grid = dayGrid(16)
        #expect(grid.rows.allSatisfy { $0.height >= 60 })
        #expect(grid.rows.count == 24)
    }
}
