import Foundation
@testable import SathiCore
import Testing

@Suite("ActivityDayStats")
struct ActivityDayStatsTests {
    typealias Fix = ActivityReportSupport

    @Test func totalsAddUpToTheTrackedSpan() {
        let day = Fix.day(4, Fix.busyDay)
        let stats = ActivityDayStats(day)
        #expect(stats.realWork == 12000)
        #expect(stats.realWork + stats.away + stats.notLogged == day.hours.duration)
        #expect(stats.tracked == day.hours.duration)
    }

    @Test func notLoggedIsEveryGapInsideHours() {
        let stats = ActivityDayStats(Fix.day(4, Fix.busyDay))
        let gaps = stats.segments.filter { $0.kind == .notLogged }
        #expect(gaps.map(\.interval) == [
            DateInterval(start: Fix.at(4, 11), end: Fix.at(4, 11, 30)),
            DateInterval(start: Fix.at(4, 12), end: Fix.at(4, 13)),
            DateInterval(start: Fix.at(4, 14, 20), end: Fix.at(4, 18))
        ])
    }

    @Test func awayIsCountedApartFromRealWork() {
        let stats = ActivityDayStats(Fix.day(4, Fix.busyDay))
        #expect(stats.away == 1800)
        #expect(stats.count == 4)
    }

    @Test func anActivityOutsideHoursIsClipped() {
        let late = Fix.work("Deploy", "Coding", 4, (17, 0), (20, 0))
        let stats = ActivityDayStats(Fix.day(4, [late]))
        #expect(stats.realWork == 3600)
        #expect(stats.realWork + stats.away + stats.notLogged == stats.tracked)
    }

    @Test func theRunningActivityCounts() {
        let running = Fix.work("Review", "Review", 4, (16, 0), (17, 0))
        let stats = ActivityDayStats(Fix.day(4, [], running: running))
        #expect(stats.realWork == 3600)
        #expect(stats.count == 1)
    }

    @Test func aDayWithNothingIsAllNotLogged() {
        let day = Fix.day(4, [])
        let stats = ActivityDayStats(day)
        #expect(stats.notLogged == day.hours.duration)
        #expect(stats.realWork == 0)
        #expect(stats.topCategory == nil)
    }

    @Test func zeroLengthHoursGiveNothing() {
        let day = ActivityDay(day: Fix.dayKey(4), hours: DateInterval(start: Fix.at(4, 9), duration: 0), activities: [])
        #expect(ActivityDayStats(day).segments.isEmpty)
    }

    @Test func overlappingItemsNeverDoubleCount() {
        let a = Fix.work("A", "Coding", 4, (9, 0), (11, 0))
        let b = Fix.work("B", "Coding", 4, (10, 0), (12, 0))
        let stats = ActivityDayStats(Fix.day(4, [a, b]))
        #expect(stats.realWork == 3 * 3600)
        #expect(stats.realWork + stats.away + stats.notLogged == stats.tracked)
    }

    @Test func categoriesAreSortedLongestFirstWithPercent() {
        let stats = ActivityDayStats(Fix.day(4, Fix.busyDay))
        #expect(stats.categories.map(\.name) == ["Coding", "Meeting", "No category"])
        #expect(stats.categories.map(\.seconds) == [9000, 1800, 1200])
        #expect(stats.categories.map(\.percent) == [75, 15, 10])
        #expect(stats.topCategory?.name == "Coding")
        #expect(stats.categories.last?.isNamed == false)
    }

    @Test func calendarCountUsesEventIDs() {
        var saved = Fix.work("Plan", "Coding", 4, (9, 0), (10, 0))
        saved.eventID = "E1"
        var fromEvent = Fix.work("Sync", "Meeting", 4, (10, 0), (11, 0), kind: .event)
        fromEvent.sourceEventID = "E2"
        let plain = Fix.work("Code", "Coding", 4, (11, 0), (12, 0))
        #expect(ActivityDayStats(Fix.day(4, [saved, fromEvent, plain])).inCalendar == 2)
    }
}
