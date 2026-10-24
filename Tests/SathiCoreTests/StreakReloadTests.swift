import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Streak after reload")
struct StreakReloadTests {
    private let base = makeTempFolder()

    private func reloadedEngine(_ data: Persisted, events: [HistoryEvent], clock: FakeClock) -> Engine {
        let state = FileStateStore(base: base, delay: 3600)
        let history = FileHistoryStore(base: base, calendar: .current, delay: 3600)
        state.savePrefs(data.prefs)
        state.saveLive(data.live)
        events.forEach(history.append)
        state.flush()
        history.flush()
        return Engine(
            store: FileStateStore(base: base, delay: 3600),
            history: FileHistoryStore(base: base, calendar: .current, delay: 3600),
            clock: clock,
            sound: SpySoundPlayer(),
            presenter: SpyPresenter()
        )
    }

    @Test func doneInTheSameSecondAsAResetGivesTheSameStreakAfterReload() {
        let h = EngineHarness(at: day(2026, 3, 4, 10).addingTimeInterval(0.2)) { $0.prefs.water.dailyGoalGlasses = 1 }
        h.engine.emergencySkip(.water)
        h.clock.advance(minutes: 0.5 / 60)
        h.engine.logWater(1)
        let before = h.engine.streak(.water)
        let after = reloadedEngine(h.engine.data, events: h.history.allEvents(), clock: h.clock).streak(.water)
        #expect(before == after)
        #expect(before == 0)
    }

    @Test func aStreakOlderThanTheMemoryWindowSurvivesAReload() {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) { $0.prefs.water.dailyGoalGlasses = 1 }
        let events = (1 ... 70).map { HistoryEvent.done(.water, 1, at: Calendar.current.date(byAdding: .day, value: -$0, to: h.clock.now)!) }
        let engine = reloadedEngine(h.engine.data, events: events, clock: h.clock)
        #expect(engine.streak(.water) == 70)
    }
}
