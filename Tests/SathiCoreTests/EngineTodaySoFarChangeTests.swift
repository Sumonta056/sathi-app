import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Today so far change")
struct EngineTodaySoFarChangeTests {
    private let now = day(2026, 3, 4, 14)

    private func work(_ d: Int, _ from: Int, _ to: Int, _ category: String = "Work") -> Activity {
        Activity(text: "Task", category: category, start: day(2026, 3, d, from), end: day(2026, 3, d, to))
    }

    private func sofar(_ activities: [Activity]) -> TodaySoFar {
        EngineHarness.tracker(at: now, activities: activities).engine.todayScreen.sofar
    }

    @Test func yesterdayIsCutAtTheSameClockTime() {
        let s = sofar([work(4, 10, 12), work(3, 10, 11), work(3, 15, 18)])
        #expect(s.logged == 2 * 3600)
        #expect(s.change == .up(3600))
    }

    @Test func lessThanYesterdaySoFarIsDown() {
        let s = sofar([work(4, 10, 11), work(3, 9, 12)])
        #expect(s.change == .down(2 * 3600))
    }

    @Test func theSameTimeAsYesterdaySoFarIsSame() {
        let s = sofar([work(4, 10, 11), work(3, 12, 13), work(3, 15, 17)])
        #expect(s.change == .same)
    }

    @Test func noDataInBothDaysHidesTheChange() {
        #expect(sofar([]).change == .none)
    }

    @Test func trackerOffHasNoChange() {
        let h = EngineHarness(at: now, activities: InMemoryActivityStore(activities: [work(4, 10, 12), work(3, 10, 11)])) {
            $0.prefs.tracker.isOn = false
        }
        #expect(h.engine.todayScreen.sofar.isOn == false)
        #expect(h.engine.todayScreen.sofar.change == .none)
        #expect(TodaySoFar.off.change == .none)
        #expect(TodaySoFar.off.away.isEmpty)
    }

    @Test func awayPlacesAreKeptApartFromTheCategories() {
        let lunch = Activity(kind: .away, text: "", start: day(2026, 3, 4, 12), end: day(2026, 3, 4, 12, 30), awayPlace: .lunch)
        let s = sofar([work(4, 10, 12), lunch])
        #expect(s.categories.map(\.name) == ["Work"])
        #expect(s.away.map(\.name) == ["Lunch"])
        #expect(s.away.map(\.seconds) == [1800])
    }

    @Test func onlyTodayHasDataBeforeTheCutShowsTheChange() {
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 9), activities: [work(4, 8, 9), work(3, 10, 18)]) {
            $0.prefs.tracker.startMinutes = 8 * 60
        }
        #expect(h.engine.todayScreen.sofar.change == .up(3600))
    }

    @Test func twoBuildsInOneDayReadYesterdaysMonthOnce() {
        let h = EngineHarness.tracker(at: day(2026, 4, 1, 14), activities: [
            Activity(text: "Task", category: "Work", start: day(2026, 3, 31, 10), end: day(2026, 3, 31, 11))
        ])
        let march = MonthKey(day(2026, 3, 31, 10), calendar: h.engine.calendar)
        _ = h.engine.todayScreen
        let first = h.activities.reads.filter { $0 == march }.count
        h.clock.now = day(2026, 4, 1, 14, 1)
        _ = h.engine.todayScreen
        #expect(first > 0)
        #expect(h.activities.reads.filter { $0 == march }.count == first)
    }

    @Test func aDataChangeRebuildsYesterday() {
        let old = work(3, 10, 11)
        let h = EngineHarness.tracker(at: now, activities: [work(4, 10, 12), old])
        #expect(h.engine.todayScreen.sofar.change == .up(3600))
        #expect(h.engine.deleteActivity(old.id))
        #expect(h.engine.todayScreen.sofar.change == .up(2 * 3600))
    }
}
