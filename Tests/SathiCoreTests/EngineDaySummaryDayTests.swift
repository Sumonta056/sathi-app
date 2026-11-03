import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine day summary day")
struct EngineDaySummaryDayTests {
    private func waterOnly(_ p: inout Persisted) {
        p.prefs.reading.enabled = false
        p.prefs.water.dailyGoalGlasses = 6
        p.events = [.done(.water, 3, at: day(2026, 3, 4, 20))]
    }

    private func status(_ h: EngineHarness, _ id: HabitID) -> DaySummaryStatus? {
        h.engine.daySummary.rows.first { $0.id == id }?.status
    }

    @Test func anOpenSummaryKeepsTheDayItOpenedFor() {
        let h = EngineHarness(at: day(2026, 3, 4, 22), configure: waterOnly)
        #expect(h.presenter.calls.contains(.showDaySummary))
        h.advance(minutes: 9 * 60)
        #expect(status(h, .water) == .progress(done: 3, goal: 6))
    }

    @Test func aGlassLoggedAfterMidnightDoesNotCountForTheOpenSummary() {
        let h = EngineHarness(at: day(2026, 3, 4, 22), configure: waterOnly)
        h.advance(minutes: 3 * 60)
        h.engine.logWater(1)
        #expect(status(h, .water) == .progress(done: 3, goal: 6))
    }

    @Test func withNoRecordedDayItDescribesToday() {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) {
            waterOnly(&$0)
            $0.events = [.done(.water, 3, at: day(2026, 3, 4, 8))]
        }
        #expect(h.engine.data.live.lastDaySummary == nil)
        #expect(status(h, .water) == .progress(done: 3, goal: 6))
    }

    @Test func aDayOffOfTheSummaryDayStaysADayOffNextMorning() {
        let h = EngineHarness(at: day(2026, 3, 4, 22)) {
            waterOnly(&$0)
            var d = $0.prefs.days(.water)
            d.daysOff.insert(DayKey(day(2026, 3, 4), calendar: .current))
            $0.prefs.setDays(.water, d)
        }
        h.advance(minutes: 9 * 60)
        #expect(status(h, .water) == .dayOff)
    }
}
