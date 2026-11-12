import Foundation
@testable import SathiCore
import Testing

@Suite("Activity range stats")
struct ActivityRangeStatsTests {
    typealias Fix = ActivityReportSupport

    private var thisWeek: [ActivityDay] {
        [
            Fix.day(4, Fix.busyDay),
            Fix.day(5, [Fix.work("Docs", "Learning", 5, (9, 0), (10, 0))]),
            Fix.day(6, [Fix.away(6, (9, 0), (10, 0))])
        ]
    }

    private var lastWeek: [ActivityDay] {
        [Fix.day(25, [Fix.work("Old", "Coding", 25, (9, 0), (10, 0))])]
    }

    @Test func tilesCompareWithTheRangeBefore() {
        let stats = ActivityRangeStats(thisWeek, compare: lastWeek)
        let total: TimeInterval = 15600
        let bestDay: TimeInterval = 12000
        #expect(stats.realWork == total)
        #expect(stats.averageDay == 7800)
        #expect(stats.realWorkChange == .up(total - 3600))
        #expect(stats.averageDayChange == .up(7800 - 3600))
        #expect(stats.bestDayChange == .up(bestDay - 3600))
        #expect(stats.awayChange == .up(1800))
        #expect(stats.bestDay?.day == Fix.dayKey(4))
    }

    @Test func noChangeIsShownWhenTheRangeBeforeHasNoData() {
        let stats = ActivityRangeStats(thisWeek, compare: [])
        #expect(stats.realWorkChange == .none)
        #expect(stats.categories.allSatisfy { $0.change == .none })
    }

    @Test func sameTotalsGiveSameAndLessGivesDown() {
        let same = ActivityRangeStats(lastWeek, compare: lastWeek)
        #expect(same.realWorkChange == .same)
        let less = ActivityRangeStats([], compare: lastWeek)
        #expect(less.realWorkChange == .down(3600))
    }

    @Test func categoriesAreLongestFirstWithChange() {
        let stats = ActivityRangeStats(thisWeek, compare: lastWeek)
        let rows = stats.categories.filter { $0.kind == .category }
        #expect(rows.map(\.name) == ["Coding", "Learning", "Meeting", Copywriter.trackerNoCategory])
        #expect(rows[0].change == .up(5400))
        #expect(rows[1].change == .up(3600))
    }

    @Test func calendarEventsAndAwayGetTheirOwnRows() {
        let event = Fix.work("Planning", "Meeting", 4, (9, 0), (10, 0), kind: .event)
        let days = [Fix.day(4, [event, Fix.away(4, (10, 0), (10, 30))])]
        let stats = ActivityRangeStats(days, compare: [])
        let events = stats.categories.first { $0.kind == .events }
        let away = stats.categories.first { $0.kind == .away }
        #expect(events?.name == Copywriter.trackerCalendarEvents)
        #expect(events?.seconds == 3600)
        #expect(away?.name == Copywriter.trackerAway)
        #expect(away?.seconds == 1800)
        #expect(stats.categories.filter { $0.kind == .category }.isEmpty)
    }

    @Test func allRowsAreLongestFirst() {
        let event = Fix.work("Planning", "Meeting", 4, (9, 0), (11, 0), kind: .event)
        let work = Fix.work("Docs", "Learning", 4, (11, 0), (11, 30))
        let days = [Fix.day(4, [event, work, Fix.away(4, (12, 0), (13, 0))])]
        let stats = ActivityRangeStats(days, compare: [])
        #expect(stats.categories.map(\.name) == [Copywriter.trackerCalendarEvents, Copywriter.trackerAway, "Learning"])
    }

    @Test func extraRowsAreLeftOutWhenThereIsNoSuchTime() {
        let stats = ActivityRangeStats(thisWeek, compare: [])
        #expect(stats.categories.contains { $0.kind == .events } == false)
    }

    @Test func realWorkAwayAndNotLoggedStillAddUpToTheTrackedSpanPerDay() {
        let stats = ActivityRangeStats(thisWeek, compare: [])
        for day in thisWeek {
            let d = ActivityDayStats(day)
            #expect(d.tracked == day.hours.duration)
        }
        #expect(stats.rows.count == 2)
    }

    @Test func rowsAreOneForEachDayWithWork() {
        let stats = ActivityRangeStats(thisWeek, compare: [])
        #expect(stats.rows.map(\.day) == [Fix.dayKey(4), Fix.dayKey(5)])
    }
}
