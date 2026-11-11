import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine range reports")
struct EngineRangeReportTests {
    private func mondayWeek(_ now: Date) -> StatsRange {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return StatsRange.containing(now, kind: .week, calendar: calendar)
    }

    private func monthsAgoHarness() -> EngineHarness {
        EngineHarness(at: day(2026, 7, 15, 10)) {
            $0.events = [
                .done(.water, 6, at: day(2026, 2, 10, 9)),
                .done(.water, 2, at: day(2026, 2, 11, 9)),
                .done(.water, 5, at: day(2026, 7, 14, 9))
            ]
        }
    }

    @Test func aRangeOlderThanTheMemoryWindowGetsItsEventsFromHistory() throws {
        let h = monthsAgoHarness()
        let february = StatsRange.containing(day(2026, 2, 20), kind: .month, calendar: .current)
        let water = try #require(h.engine.buddyRange(february).totals.first { $0.habit == .water })
        #expect(water.total == 8)
        #expect(h.engine.report(february).habits.first { $0.habit == .water }?.total == 8)
    }

    @Test func recentEventsComeFromMemory() {
        let h = monthsAgoHarness()
        h.history.clearRanges()
        let july = StatsRange.containing(day(2026, 7, 15), kind: .month, calendar: .current)
        #expect(h.engine.buddyRange(july).totals.first { $0.habit == .water }?.total == 5)
        #expect(h.history.ranges.isEmpty)
    }

    @Test func theCurrentWeekReportEqualsTheOldWeekReport() {
        let h = EngineHarness {
            $0.events = [
                .done(.water, 3, at: day(2026, 3, 2, 10)),
                .done(.water, 4, at: day(2026, 3, 3, 10)),
                .snooze(.water, at: day(2026, 3, 3, 11))
            ]
        }
        let range = mondayWeek(h.clock.now)
        #expect(h.engine.report(range) == h.engine.report(.week))
    }

    @Test func theScreenForTheCurrentWeekEqualsTheOldWeekScreen() {
        let h = EngineHarness {
            $0.events = [.done(.water, 3, at: day(2026, 3, 2, 10))]
        }
        let range = mondayWeek(h.clock.now)
        #expect(h.engine.reportScreen(range, selected: .water) == h.engine.reportScreen(.week, selected: .water))
    }
}
