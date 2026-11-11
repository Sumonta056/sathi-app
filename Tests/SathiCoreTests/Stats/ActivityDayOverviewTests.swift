import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Activity day overview")
struct ActivityDayOverviewTests {
    private func at(_ h: Int, _ m: Int = 0) -> Date { day(2026, 3, 4, h, m) }

    private func work(_ text: String, _ category: String?, _ from: (Int, Int), _ to: (Int, Int), kind: ActivityKind = .work) -> Activity {
        Activity(kind: kind, text: text, category: category, start: at(from.0, from.1), end: at(to.0, to.1))
    }

    private func away(_ place: AwayPlace, _ from: (Int, Int), _ to: (Int, Int), name: String? = nil) -> Activity {
        Activity(kind: .away, text: "Away", start: at(from.0, from.1), end: at(to.0, to.1), awayPlace: place, awayPlaceName: name)
    }

    private func make(_ items: [Activity], change: RangeChange = .none) -> ActivityDayOverview {
        let d = ActivityDay(day: DayKey(at(12), calendar: .current), hours: DateInterval(start: at(9), end: at(18)), activities: items)
        return ActivityDayOverview(d, loggedChange: change)
    }

    private var sample: [Activity] {
        [
            work("Spec", "Coding", (9, 0), (10, 0)),
            work("Standup", "Meeting", (10, 0), (10, 30), kind: .event),
            away(.lunch, (12, 0), (12, 45)),
            work("Read", "Reading", (13, 0), (13, 30), kind: .buddy),
            away(.walk, (15, 0), (15, 10)),
            away(.lunch, (16, 0), (16, 5)),
            work("Deep work", "Coding", (17, 0), (17, 30), kind: .timeBlock)
        ]
    }

    @Test func loggedIsTheWorkTimeAndKeepsTheChange() {
        let o = make(sample, change: .up(600))
        #expect(o.logged == 150 * 60)
        #expect(o.loggedChange == .up(600))
    }

    @Test func focusIsOwnWorkAndTimeBlocksButNotEventsOrBuddySessions() {
        let o = make(sample)
        #expect(o.focus == 90 * 60)
        #expect(o.focusPercent == 60)
    }

    @Test func focusPercentIsEmptyWithNothingLogged() {
        #expect(make([]).focusPercent == nil)
    }

    @Test func awayCountsEachAwaySpanAndNamesThePlaceWithTheMostTime() {
        let o = make(sample)
        #expect(o.away == 60 * 60)
        #expect(o.awayCount == 3)
        #expect(o.topPlace == "Lunch")
    }

    @Test func aNamedOtherPlaceUsesItsName() {
        let o = make([away(.other, (12, 0), (12, 30), name: "Doctor"), away(.walk, (13, 0), (13, 10))])
        #expect(o.topPlace == "Doctor")
    }

    @Test func noAwayHasNoPlace() {
        let o = make([work("Spec", "Coding", (9, 0), (10, 0))])
        #expect(o.awayCount == 0)
        #expect(o.topPlace == nil)
    }

    @Test func countIsTheActivitiesWithoutAwayAndTopIsTheLargestCategory() {
        let o = make(sample)
        #expect(o.count == 4)
        #expect(o.topCategory == "Coding")
        #expect(o.categories.map(\.name) == ["Coding", "Meeting", "Reading"])
    }

    @Test func gapsCountTheNotLoggedSpansOfAMinuteOrMore() {
        let o = make([work("Spec", "Coding", (9, 0), (10, 0)), work("Mail", nil, (10, 0), (18, 0))])
        #expect(o.gaps == 0)
        #expect(make(sample).gaps == 6)
    }
}

@MainActor
@Suite("Engine activity day overview")
struct EngineActivityDayOverviewTests {
    @Test func theOverviewComparesWithTheDayBefore() {
        let items = [
            Activity(text: "Spec", category: "Coding", start: day(2026, 3, 4, 9), end: day(2026, 3, 4, 10)),
            Activity(text: "Old", category: "Coding", start: day(2026, 3, 3, 9), end: day(2026, 3, 3, 9, 30))
        ]
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 12), activities: items)
        let o = h.engine.activityDayOverview(StatsRange.containing(h.clock.now, kind: .day, calendar: h.engine.calendar))
        #expect(o.logged == 3600)
        #expect(o.loggedChange == RangeChange.up(1800))
        #expect(o.topCategory == "Coding")
    }
}
