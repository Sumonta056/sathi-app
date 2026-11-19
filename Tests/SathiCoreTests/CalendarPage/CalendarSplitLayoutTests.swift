import Foundation
@testable import SathiCore
import Testing

@Suite("Calendar split layout: halves and positions")
struct CalendarSplitLayoutTests {
    private let tenAM = 240.0
    private let elevenAM = 300.0

    @Test func activitiesAreActualAndEventsArePlan() {
        let grid = Split.layout([
            Split.activity("work", "10:00", "11:00"), Split.away("away", "12:00", "13:00"), Split.event("meet", "10:00", "11:00")
        ])
        #expect(Split.laid(grid, "work")?.half == .actual)
        #expect(Split.laid(grid, "away")?.half == .actual)
        #expect(Split.laid(grid, "meet")?.half == .plan)
    }

    @Test func actualAndPlanNeverShareLanes() {
        let grid = Split.layout([Split.activity("work", "10:00", "11:00"), Split.event("meet", "10:10", "11:00")])
        let work = Split.laid(grid, "work")
        let meet = Split.laid(grid, "meet")
        #expect(work?.lanes == 1)
        #expect(work?.depth == 0)
        #expect(meet?.lanes == 1)
        #expect(meet?.depth == 0)
        #expect(meet?.top == tenAM + 10)
    }

    @Test func blockRunsFromItsRealStartToItsRealEnd() {
        let grid = Split.layout([Split.activity("work", "10:00", "11:00")])
        let work = Split.laid(grid, "work")
        #expect(work?.top == tenAM)
        #expect(work?.bottom == elevenAM)
        #expect(work?.span == Split.span("10:00", "11:00"))
    }

    @Test func shortBlockGetsTheMinimumHeight() {
        let grid = Split.layout([Split.activity("work", "10:00", "10:10")])
        #expect(Split.laid(grid, "work")?.top == tenAM)
        #expect(Split.laid(grid, "work")?.bottom == tenAM + Split.day.minHeight)
    }

    @Test func weekUsesItsOwnMinimumHeight() {
        let grid = Split.layout([Split.activity("work", "10:00", "10:10")], metrics: Split.weekFlat)
        #expect(Split.laid(grid, "work")?.bottom == tenAM + Split.weekFlat.minHeight)
    }

    @Test func awayUnderFiveMinutesStillShowsWithTheAwayMinimum() {
        let grid = Split.layout([Split.away("blink", "10:00", "10:03")])
        let blink = Split.laid(grid, "blink")
        #expect(blink != nil)
        #expect(blink?.top == tenAM)
        #expect(blink?.bottom == tenAM + Split.day.awayMinHeight)
    }

    @Test func zoomScalesPositionsByPointsPerMinute() {
        let ppm = 2.0
        let zoomed = Split.metrics(pointsPerMinute: ppm, minHeight: 46, awayMinHeight: 40, gap: 4, folds: false)
        let grid = Split.layout([Split.activity("work", "10:00", "10:15")], rowMinutes: 30, metrics: zoomed)
        #expect(Split.laid(grid, "work")?.top == tenAM * ppm)
        #expect(Split.laid(grid, "work")?.bottom == tenAM * ppm + zoomed.minHeight)
    }

    @Test func blockIsPushedExactlyOneGapUnderTheBlockAbove() {
        let grid = Split.layout([Split.activity("a", "10:00", "10:05"), Split.activity("b", "10:10", "10:40")], metrics: Split.weekFlat)
        let a = Split.laid(grid, "a")
        let b = Split.laid(grid, "b")
        #expect(a?.top == tenAM)
        #expect(a?.bottom == tenAM + Split.weekFlat.minHeight)
        #expect(b?.top == tenAM + Split.weekFlat.minHeight + Split.weekFlat.gap)
        #expect(b?.bottom == tenAM + Split.weekFlat.minHeight + Split.weekFlat.gap + Split.weekFlat.minHeight)
        #expect(a?.lanes == 1)
        #expect(b?.lanes == 1)
        #expect(b?.depth == 0)
    }

    @Test func pushedBlockKeepsItsRealEndWhenThatIsLower() {
        let grid = Split.layout([Split.activity("a", "10:00", "10:05"), Split.activity("b", "10:10", "11:20")], metrics: Split.weekFlat)
        #expect(Split.laid(grid, "b")?.top == tenAM + Split.weekFlat.minHeight + Split.weekFlat.gap)
        #expect(Split.laid(grid, "b")?.bottom == elevenAM + 20)
    }

    @Test func blocksThatOnlyTouchDoNotOverlap() {
        let grid = Split.layout([Split.event("a", "10:00", "11:00"), Split.event("b", "11:00", "12:00")])
        let a = Split.laid(grid, "a")
        let b = Split.laid(grid, "b")
        #expect(a?.lanes == 1)
        #expect(b?.lanes == 1)
        #expect(b?.depth == 0)
        #expect((b?.top ?? 0) >= (a?.bottom ?? .infinity))
    }

    @Test func blockNeverMovesUp() {
        let grid = Split.layout([Split.event("a", "10:00", "12:00"), Split.event("b", "10:40", "11:00")])
        #expect(Split.laid(grid, "b")?.top == tenAM + 40)
    }

    @Test func spanIsCutToThePageDay() {
        var block = Split.away("night", "04:00", "05:00")
        block.interval = DateInterval(start: Split.at("04:00"), end: Split.at("07:00", on: Split.monday + 1))
        let grid = Split.layout([block])
        let tuesday = Split.key(Split.monday + 1)
        let night = Split.laid(grid, "night")
        #expect(night?.span == DateInterval(start: Split.at("04:00"), end: CalendarPageDay.interval(of: Split.page, calendar: Split.calendar).end))
        #expect(grid.days[tuesday] == nil)
    }

    @Test func allDayBlocksAreNotInTheGrid() {
        var block = Split.event("holiday", "06:00", "05:59")
        block.isAllDay = true
        let grid = Split.layout([block, Split.event("meet", "10:00", "11:00")])
        #expect(Split.laid(grid, "holiday") == nil)
        #expect(Split.laid(grid, "meet") != nil)
    }

    @Test func everyShownDayHasAnEntry() {
        let days = [Split.key(15), Split.key(16), Split.key(17)]
        let grid = Split.layout([], days: days)
        #expect(Set(grid.days.keys) == Set(days))
    }

    @Test func layoutHasNoOverlapProblems() {
        let grid = Split.layout([
            Split.activity("a", "10:00", "10:05"), Split.activity("b", "10:10", "10:40"), Split.activity("c", "10:12", "10:20"),
            Split.away("d", "10:41", "10:43"), Split.activity("e", "10:44", "11:30"), Split.event("f", "10:00", "10:30"),
            Split.event("g", "10:20", "10:50"), Split.event("h", "10:55", "11:00")
        ])
        #expect(SplitCheck.problems(grid, metrics: Split.day) == [])
    }
}
