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
}
