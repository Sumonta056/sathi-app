import Foundation
@testable import SathiCore
import Testing

@Suite("Calendar split layout: night fold")
struct CalendarNightFoldTests {
    private func strips(_ grid: CalendarGridLayout) -> [String] {
        grid.rows.map { "\($0.startMinute)-\($0.endMinute)\($0.isFold ? " fold" : "")" }
    }

    @Test func quietRunsBecomeOneStrip() {
        let grid = Split.layout(
            [Split.activity("work", "10:00", "11:00"), Split.away("sleep", "01:00", "05:00")], metrics: Split.week
        )
        #expect(strips(grid) == ["0-240 fold", "240-300", "300-1440 fold"])
        #expect(grid.rows.map(\.height) == [22, 60, 22])
        #expect(grid.rows.map(\.top) == [0, 22, 82])
        #expect(grid.height == 104)
        #expect(Split.laid(grid, "work")?.top == 22)
        #expect(Split.laid(grid, "work")?.bottom == 82)
    }

    @Test func singleQuietRowDoesNotFold() {
        let grid = Split.layout(
            [Split.activity("a", "09:00", "10:00"), Split.activity("b", "11:00", "12:00")], metrics: Split.week
        )
        #expect(strips(grid) == ["0-180 fold", "180-240", "240-300", "300-360", "360-1440 fold"])
        #expect(grid.rowAt(2)?.height == 60)
    }

    @Test func rowCrossedByANonAwayBlockNeverFolds() {
        let grid = Split.layout([Split.activity("long", "13:00", "16:00")], metrics: Split.week)
        #expect(strips(grid) == ["0-420 fold", "420-480", "480-540", "540-600", "600-1440 fold"])
    }

    @Test func eventsKeepTheirRowsOpen() {
        let grid = Split.layout([Split.event("plan", "13:00", "16:00")], metrics: Split.week)
        #expect(strips(grid) == ["0-420 fold", "420-480", "480-540", "540-600", "600-1440 fold"])
    }

    @Test func awayOnlyRowsFold() {
        let grid = Split.layout([Split.away("out", "13:00", "16:00")], metrics: Split.week)
        #expect(strips(grid) == ["0-1440 fold"])
        #expect(grid.rowAt(0)?.height == Split.week.foldHeight)
    }

    @Test func aRowBusyOnAnyShownDayStaysOpenForAllDays() {
        let tuesday = Split.key(Split.monday + 1)
        let grid = Split.layout(
            [Split.activity("mon", "07:00", "08:00"), Split.away("tue", "07:00", "08:00", on: Split.monday + 1)],
            days: [Split.page, tuesday], metrics: Split.week
        )
        #expect(strips(grid) == ["0-60", "60-120", "120-1440 fold"])
    }

    @Test func todoKeepsItsRowOpenAndSitsAtItsDueTime() {
        let grid = Split.layout([Split.todo("pay", "07:30"), Split.activity("work", "12:00", "13:00")], metrics: Split.week)
        #expect(strips(grid) == ["0-60", "60-120", "120-360 fold", "360-420", "420-1440 fold"])
        #expect(Split.laid(grid, "pay")?.top == 90)
        #expect(Split.laid(grid, "work")?.top == 142)
    }

    @Test func zoomedQuietRowsFoldToo() {
        let m = Split.metrics(pointsPerMinute: 2, minHeight: 34, awayMinHeight: 34, gap: 2, folds: true)
        let grid = Split.layout([Split.activity("work", "06:30", "07:00")], rowMinutes: 30, metrics: m)
        #expect(strips(grid) == ["0-30", "30-60", "60-1440 fold"])
    }

    @Test func dayNeverFolds() {
        let grid = Split.layout([Split.activity("work", "10:00", "11:00")], metrics: Split.day)
        #expect(grid.rows.count == 24)
        #expect(grid.rows.allSatisfy { !$0.isFold })
    }

    @Test func emptyWeekFoldsWholeDay() {
        let grid = Split.layout([], days: [Split.page, Split.key(Split.monday + 1)], metrics: Split.weekNarrow)
        #expect(strips(grid) == ["0-1440 fold"])
    }

    @Test func awayInsideAFoldIsNotShown() {
        let grid = Split.layout(
            [Split.activity("work", "10:00", "11:00"), Split.away("sleep", "01:00", "05:00")], metrics: Split.week
        )
        #expect(Split.laid(grid, "sleep") == nil)
        #expect(grid.days[Split.page]?.contains { $0.hidden.contains { $0.id == "sleep" } } == false)
    }

    @Test func awayLeavingAFoldStartsAtTheStripBottom() {
        let real = DateInterval(start: Split.at("04:00", on: Split.monday - 1), end: Split.at("10:30"))
        let grid = Split.layout(
            [Split.activity("work", "10:00", "11:00"), Split.activity("sleep", real, kind: .away)], metrics: Split.week
        )
        let strip = grid.rowAt(0)
        #expect(strip?.isFold == true)
        #expect(Split.laid(grid, "sleep")?.top == strip.map { $0.top + $0.height })
    }
}
