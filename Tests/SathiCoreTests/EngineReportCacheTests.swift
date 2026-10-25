import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine report cache")
struct EngineReportCacheTests {
    private func harness() -> EngineHarness {
        EngineHarness {
            $0.events = [.done(.water, 3, at: day(2026, 3, 3, 12)), .done(.reading, 1, at: day(2026, 3, 2, 22))]
        }
    }

    private func reads(_ h: EngineHarness) -> Int { h.history.ranges.count }

    @Test func twoCallsWithTheSameKeyReadHistoryOnce() {
        let h = harness()
        h.history.clearRanges()
        let first = h.engine.reportScreen(.week, selected: .water)
        let afterFirst = reads(h)
        #expect(afterFirst > 0)
        let second = h.engine.reportScreen(.week, selected: .water)
        #expect(reads(h) == afterFirst)
        #expect(second == first)
    }

    @Test func aLaterTimeOnTheSameDayKeepsTheCache() {
        let h = harness()
        _ = h.engine.reportScreen(.week, selected: .water)
        h.history.clearRanges()
        h.clock.advance(minutes: 1)
        _ = h.engine.reportScreen(.week, selected: .water)
        #expect(reads(h) == 0)
    }

    @Test func aNewDoneEventRebuilds() {
        let h = harness()
        let before = h.engine.reportScreen(.week, selected: .water)
        h.history.clearRanges()
        h.engine.logWater(2)
        let after = h.engine.reportScreen(.week, selected: .water)
        #expect(reads(h) > 0)
        #expect(after != before)
    }

    @Test func aGoalChangeRebuilds() {
        let h = harness()
        let before = h.engine.reportScreen(.week, selected: .water)
        h.history.clearRanges()
        h.engine.data.prefs.water.dailyGoalGlasses = 12
        let after = h.engine.reportScreen(.week, selected: .water)
        #expect(reads(h) > 0)
        #expect(after.chart.goal == 12)
        #expect(after != before)
    }

    @Test func anEnabledChangeRebuilds() {
        let h = harness()
        let before = h.engine.reportScreen(.week, selected: .water)
        h.history.clearRanges()
        h.engine.data.prefs.reading.enabled = false
        let after = h.engine.reportScreen(.week, selected: .water)
        #expect(reads(h) > 0)
        #expect(after.tiles.first { $0.habit == .reading }?.isOff == true)
        #expect(after != before)
    }

    @Test func aNewDayRebuilds() {
        let h = harness()
        _ = h.engine.reportScreen(.week, selected: .water)
        h.history.clearRanges()
        h.clock.advance(minutes: 24 * 60)
        _ = h.engine.reportScreen(.week, selected: .water)
        #expect(reads(h) > 0)
    }

    @Test func aNewRangeRebuilds() {
        let h = harness()
        _ = h.engine.reportScreen(.week, selected: .water)
        h.history.clearRanges()
        let month = h.engine.reportScreen(.month, selected: .water)
        #expect(reads(h) > 0)
        #expect(month.range == .month)
    }

    @Test func aNewSelectedHabitRebuilds() {
        let h = harness()
        _ = h.engine.reportScreen(.week, selected: .water)
        h.history.clearRanges()
        let reading = h.engine.reportScreen(.week, selected: .reading)
        #expect(reads(h) > 0)
        #expect(reading.selected == .reading)
    }

    @Test func goingBackToAnEarlierKeyStillShowsFreshData() {
        let h = harness()
        _ = h.engine.reportScreen(.week, selected: .water)
        _ = h.engine.reportScreen(.week, selected: .reading)
        h.engine.logWater(2)
        let water = h.engine.reportScreen(.week, selected: .water)
        let tile = water.tiles.first { $0.habit == .water }
        let fresh = ReportScreenBuilder(calendar: .current).build(ReportScreenInput(
            range: .week,
            selected: .water,
            report: h.engine.report(.week),
            month: h.engine.report(.month),
            enabled: [.water, .reading],
            streak: h.engine.streak(.water),
            longest: h.engine.longestStreak(.water),
            now: h.clock.now
        ))
        #expect(tile == fresh.tiles.first { $0.habit == .water })
    }
}
