import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Dashboard memo")
struct DashboardMemoTests {
    private final class Counter {
        var builds = 0
    }

    private func harness() -> EngineHarness {
        EngineHarness(at: day(2026, 11, 11, 20)) {
            $0.prefs.water.dailyGoalGlasses = 8
            $0.prefs.reading.sessionMinutes = 15
            $0.events = [
                .done(.water, 8, at: day(2026, 11, 10, 9)),
                .done(.reading, 15, at: day(2026, 11, 10, 21)),
                .done(.water, 8, at: day(2026, 11, 11, 9))
            ]
        }
    }

    private func read(_ memo: DashboardMemo, _ h: EngineHarness, _ c: Counter) -> DashboardScore? {
        let range = StatsRange.containing(h.clock.now, kind: .day, calendar: h.engine.calendar)
        return memo.score(range, overview: h.engine.reportsOverview(range), engine: h.engine) { e, r in
            c.builds += 1
            return e.dashboardYesterday(r)
        }
    }

    @Test func twoMinuteTicksInTheSameDayBuildYesterdayOnce() {
        let h = harness()
        let memo = DashboardMemo()
        let c = Counter()
        _ = read(memo, h, c)
        h.clock.now = h.clock.now.addingTimeInterval(60)
        h.clock.now = h.clock.now.addingTimeInterval(60)
        _ = read(memo, h, c)
        #expect(c.builds == 1)
    }

    @Test func aDataChangeRebuildsYesterday() {
        let h = harness()
        let memo = DashboardMemo()
        let c = Counter()
        _ = read(memo, h, c)
        h.engine.logWater(1)
        _ = read(memo, h, c)
        #expect(c.builds == 2)
    }

    @Test func theCachedScoreStillCutsYesterdayAtTheClockTime() throws {
        let h = harness()
        let memo = DashboardMemo()
        let c = Counter()
        let early = try #require(read(memo, h, c))
        #expect(early.changeText == "same as yesterday")
        h.clock.now = day(2026, 11, 11, 21, 30)
        let late = try #require(read(memo, h, c))
        #expect(late.changeText == "\u{2212}1 vs yesterday")
        #expect(c.builds == 1)
        #expect(late == h.engine.dashboardScore)
    }

    @Test func theDateLineIsTheTodayDateLine() {
        let h = harness()
        #expect(DashboardMemo().dateLine(engine: h.engine) == h.engine.todayScreen.dateLine)
    }
}
