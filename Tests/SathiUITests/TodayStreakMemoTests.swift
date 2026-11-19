import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import Testing

@MainActor
@Suite("Today streak memo")
struct TodayStreakMemoTests {
    private final class Counter {
        var builds = 0
    }

    private func month(_ h: EngineHarness) -> StatsRange {
        StatsRange.containing(h.clock.now, kind: .month, calendar: h.engine.rangeCalendar)
    }

    private func read(_ memo: RangeMemo<StatsRange, OverviewMonth>, _ h: EngineHarness, _ c: Counter) -> OverviewMonth {
        TodayLowerRow.streakMonth(month(h), memo: memo, engine: h.engine) { e, r in
            c.builds += 1
            return e.streakOverview(r)
        }
    }

    @Test func minuteTicksInTheSameDayBuildTheStreakOnce() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        let memo = RangeMemo<StatsRange, OverviewMonth>()
        let c = Counter()
        _ = read(memo, h, c)
        h.advance(minutes: 1)
        _ = read(memo, h, c)
        h.advance(minutes: 1)
        _ = read(memo, h, c)
        #expect(c.builds == 1)
    }

    @Test func aNewDayRebuildsTheStreak() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        let memo = RangeMemo<StatsRange, OverviewMonth>()
        let c = Counter()
        _ = read(memo, h, c)
        h.clock.now = day(2026, 3, 5, 10)
        _ = read(memo, h, c)
        #expect(c.builds == 2)
    }

    @Test func aRealDataChangeRebuildsTheStreak() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        let memo = RangeMemo<StatsRange, OverviewMonth>()
        let c = Counter()
        _ = read(memo, h, c)
        h.engine.data.prefs.water.enabled.toggle()
        _ = read(memo, h, c)
        #expect(c.builds == 2)
    }

    @Test func theDefaultBuildIsTheStreakOverview() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        let shown = TodayLowerRow.streakMonth(month(h), memo: RangeMemo(), engine: h.engine)
        #expect(shown == h.engine.streakOverview(month(h)))
        #expect(shown.title == "March 2026")
    }
}
