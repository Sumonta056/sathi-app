import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Activity gaps")
struct ActivityGapsTests {
    private func at(_ h: Int, _ m: Int = 0) -> Date { day(2026, 3, 4, h, m) }

    private var sample: ActivityDay {
        ActivityDay(
            day: DayKey(at(12), calendar: .current), hours: DateInterval(start: at(9), end: at(18)),
            activities: [Activity(text: "Spec", category: "Coding", start: at(10), end: at(11))]
        )
    }

    @Test func aPastDayKeepsEveryGapToTheEndOfTheHours() {
        let spans = ActivityGaps.spans(sample, now: day(2026, 3, 5, 9), isTrackerDay: true)
        #expect(spans == [DateInterval(start: at(9), end: at(10)), DateInterval(start: at(11), end: at(18))])
    }

    @Test func todayEndsTheLastGapNow() {
        let spans = ActivityGaps.spans(sample, now: at(12, 30), isTrackerDay: true)
        #expect(spans == [DateInterval(start: at(9), end: at(10)), DateInterval(start: at(11), end: at(12, 30))])
    }

    @Test func aGapThatStartsAfterNowIsNotShown() {
        #expect(ActivityGaps.spans(sample, now: at(9, 30), isTrackerDay: true) == [DateInterval(start: at(9), end: at(9, 30))])
        #expect(ActivityGaps.spans(sample, now: day(2026, 3, 4, 11).addingTimeInterval(30), isTrackerDay: true).count == 1)
    }

    @Test func aDayThatIsNotATrackerDayHasNoGaps() {
        #expect(ActivityGaps.spans(sample, now: day(2026, 3, 5, 9), isTrackerDay: false).isEmpty)
        #expect(ActivityDayOverview(sample, loggedChange: .none, now: day(2026, 3, 5, 9), isTrackerDay: false).gaps == 0)
    }

    @Test func theOverviewCountsTheClampedGaps() {
        let o = ActivityDayOverview(sample, loggedChange: .none, now: at(12, 30), isTrackerDay: true)
        #expect(o.gapSpans == [DateInterval(start: at(9), end: at(10)), DateInterval(start: at(11), end: at(12, 30))])
        #expect(o.gaps == 2)
    }

    @Test func theEngineOverviewEndsTodaysGapsNow() {
        let h = EngineHarness.tracker(at: at(12, 30), activities: sample.activities)
        let o = h.engine.activityDayOverview(StatsRange.containing(h.clock.now, kind: .day, calendar: h.engine.calendar))
        #expect(o.gapSpans.last?.end == at(12, 30))
    }

    @Test func theEngineOverviewHasNoGapsOnADayOff() {
        let h = EngineHarness.tracker(at: at(12, 30), activities: sample.activities) {
            $0.prefs.tracker.daysOff = [DayKey(day(2026, 3, 4, 12), calendar: .current)]
        }
        let o = h.engine.activityDayOverview(StatsRange.containing(h.clock.now, kind: .day, calendar: h.engine.calendar))
        #expect(o.gaps == 0)
    }
}
