import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine calendar page grid")
struct EngineCalendarGridTests {
    private let dayMetrics = CalendarLayoutMetrics(
        pointsPerMinute: 1, minHeight: 46, awayMinHeight: 40, compactHeight: nil, gap: 4, titleRoom: 22, foldHeight: 22, foldsNights: false
    )
    private let weekMetrics = CalendarLayoutMetrics(
        pointsPerMinute: 1, minHeight: 34, awayMinHeight: 34, compactHeight: nil, gap: 2, titleRoom: 22, foldHeight: 22, foldsNights: true
    )

    private func event(_ id: String, _ from: Date, _ to: Date) -> CalendarEventInfo {
        CalendarEventInfo(id: id, title: id, start: from, end: to, calendarID: "work")
    }

    private func harness(_ activities: [Activity] = []) -> EngineHarness {
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 12), activities: activities)
        h.calendarWriter.eventsValue = [
            event("a", day(2026, 3, 4, 9), day(2026, 3, 4, 9, 8)),
            event("c", day(2026, 3, 5, 9), day(2026, 3, 5, 10))
        ]
        return h
    }

    private func range(_ h: EngineHarness, _ kind: ReportRange) -> CalendarPageRange {
        .containing(day(2026, 3, 4, 12), kind: kind, calendar: h.engine.calendar)
    }

    private var wed: DayKey { DayKey(day(2026, 3, 4), calendar: Calendar.current) }

    private func block(_ grid: CalendarGridLayout?, titled title: String) -> CalendarLaidBlock? {
        grid?.days[wed]?.first { $0.block.title == title }
    }

    @Test(arguments: [ReportRange.day, .week])
    func dayAndWeekHoldAGridForEveryShownDay(_ kind: ReportRange) {
        let h = harness()
        let data = h.engine.calendarPage(range(h, kind), metrics: dayMetrics)
        let grid = data.grid
        #expect(grid != nil)
        #expect(grid.map { Set($0.days.keys) } == Set(data.range.days))
        #expect(grid?.rows.first?.startMinute == 0)
        #expect(kind == .week || grid?.rows.last?.endMinute == Limits.minutesPerDay)
        #expect(block(grid, titled: "a")?.half == .plan)
    }

    @Test func dayNeverFoldsWhateverTheMetricsSay() {
        let h = harness()
        var folding = dayMetrics
        folding.foldsNights = true
        let grid = h.engine.calendarPage(range(h, .day), metrics: folding).grid
        #expect(grid?.rows.count == 24)
        #expect(grid?.rows.contains(where: \.isFold) == false)
    }

    @Test func weekFoldsQuietNightsWhateverTheMetricsSay() {
        let h = harness()
        var flat = weekMetrics
        flat.foldsNights = false
        let grid = h.engine.calendarPage(range(h, .week), metrics: flat).grid
        #expect(grid?.rows.contains(where: \.isFold) == true)
    }

    @Test(arguments: [ReportRange.day, .week])
    func gridPathKeepsBlocks(_ kind: ReportRange) {
        let h = harness()
        let data = h.engine.calendarPage(range(h, kind), metrics: weekMetrics)
        #expect(data.grid != nil)
        #expect(!data.blocks.isEmpty)
    }

    @Test func monthHasNoGrid() {
        let h = harness()
        #expect(h.engine.calendarPage(range(h, .month), metrics: dayMetrics).grid == nil)
    }

    @Test func gridFollowsTheRowZoom() {
        let h = harness()
        h.engine.setCalendarRowMinutes(30)
        let zoomed = CalendarLayoutMetrics(
            pointsPerMinute: 2, minHeight: 46, awayMinHeight: 40, compactHeight: nil, gap: 4, titleRoom: 22, foldHeight: 22, foldsNights: false
        )
        let grid = h.engine.calendarPage(range(h, .day), metrics: zoomed).grid
        #expect(grid?.rows.count == 48)
        #expect(grid?.rowAt(1)?.startMinute == 30)
        #expect(grid?.rows.allSatisfy { $0.height >= 60 } == true)
    }

    @Test func gridFollowsTheMetrics() {
        let h = harness()
        let day = block(h.engine.calendarPage(range(h, .day), metrics: dayMetrics).grid, titled: "a")
        let week = block(h.engine.calendarPage(range(h, .day), metrics: weekMetrics).grid, titled: "a")
        #expect(day.map { $0.bottom - $0.top } == dayMetrics.minHeight)
        #expect(week.map { $0.bottom - $0.top } == weekMetrics.minHeight)
    }

    @Test func gridMatchesTheCoreLayoutOfThePageBlocks() {
        let h = harness()
        let data = h.engine.calendarPage(range(h, .week), metrics: weekMetrics)
        let expected = CalendarSplitLayout.layout(
            data.blocks, days: data.range.days, calendar: h.engine.calendar, rowMinutes: 60, metrics: weekMetrics,
            now: h.engine.now
        )
        #expect(data.grid == expected)
    }

    @Test func theWeekKeepsTheRowThatHoldsNowOpen() {
        let h = harness()
        let grid = h.engine.calendarPage(range(h, .week), metrics: weekMetrics).grid
        let noon = 6 * 60
        #expect(grid?.rows.contains { $0.holds(noon) && !$0.isFold } == true)
    }

    @Test func eventWrittenForAnActivityIsNotInTheGrid() {
        let row = Activity(text: "Code", start: day(2026, 3, 4, 9), end: day(2026, 3, 4, 9, 8), eventID: "a")
        let h = harness([row])
        let grid = h.engine.calendarPage(range(h, .day), metrics: dayMetrics).grid
        let all = (grid?.days[wed] ?? []).flatMap { [$0] + $0.hidden }
        #expect(!all.contains { $0.half == .plan })
        #expect(all.contains { $0.half == .actual && $0.block.title == "Code" })
    }

    @Test func eventStartedAsAnActivityStaysInPlanWithTheLink() {
        let row = Activity(text: "Standup", start: day(2026, 3, 4, 9, 1), end: day(2026, 3, 4, 9, 7), sourceEventID: "a")
        let h = harness([row])
        let grid = h.engine.calendarPage(range(h, .day), metrics: dayMetrics).grid
        let plan = block(grid, titled: "a")
        let actual = block(grid, titled: "Standup")
        #expect(plan?.half == .plan)
        #expect(actual?.half == .actual)
        #expect(actual?.doneDuring != nil)
        #expect(actual?.doneDuring == plan?.id)
        #expect(plan?.doneDuringCount == 1)
    }
}
