import Foundation
@testable import SathiCore
import Testing

@Suite("Today v2 copy and share")
struct TodayV2CopyTests {
    private let start = Date(timeIntervalSince1970: 1_000_000)

    private func hours(_ length: TimeInterval) -> DateInterval { DateInterval(start: start, duration: length) }

    @Test func shareIsLoggedOverElapsedHours() {
        let now = start.addingTimeInterval(4 * 3600)
        #expect(TodayShare.percent(logged: 3 * 3600, hours: hours(10 * 3600), now: now) == 75)
    }

    @Test func shareCapsAtOneHundred() {
        let now = start.addingTimeInterval(3600)
        #expect(TodayShare.percent(logged: 2 * 3600, hours: hours(10 * 3600), now: now) == 100)
    }

    @Test func shareStopsGrowingAfterHoursEnd() {
        let now = start.addingTimeInterval(20 * 3600)
        #expect(TodayShare.percent(logged: 5 * 3600, hours: hours(10 * 3600), now: now) == 50)
    }

    @Test func shareIsNilWithoutHoursOrBeforeStart() {
        #expect(TodayShare.percent(logged: 60, hours: nil, now: start) == nil)
        #expect(TodayShare.percent(logged: 60, hours: hours(3600), now: start.addingTimeInterval(-60)) == nil)
    }

    @Test func summaryHidesShareWhenUnknown() {
        #expect(Copywriter.todayLoggedSummary(percent: nil) == "logged")
        #expect(Copywriter.todayLoggedSummary(percent: 85) == "logged · 85% of tracker hours")
    }

    @Test func inMinutesBadge() {
        #expect(Copywriter.todayInMinutes(0) == "now")
        #expect(Copywriter.todayInMinutes(-30) == "now")
        #expect(Copywriter.todayInMinutes(61) == "in 2 min")
        #expect(Copywriter.todayInMinutes(4 * 60) == "in 4 min")
        #expect(Copywriter.todayInMinutes(65 * 60) == "in 1h 5m")
    }

    @Test func categoryCount() {
        #expect(Copywriter.todayCategoryCount(1) == "1 category")
        #expect(Copywriter.todayCategoryCount(10) == "10 categories")
    }

    @Test func timeAndDetail() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
        let t = Date(timeIntervalSince1970: 0)
        let clock = Copywriter.trackerClock(t, calendar: cal)
        #expect(Copywriter.todayTimeAndDetail(t, detail: nil, calendar: cal) == clock)
        #expect(Copywriter.todayTimeAndDetail(t, detail: "Code", calendar: cal) == clock + " · Code")
        #expect(Copywriter.todayNowAt(t, calendar: cal) == "Now " + clock)
    }
}
