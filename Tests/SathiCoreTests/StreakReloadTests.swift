import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Streak after reload")
struct StreakReloadTests {
    private let base = makeTempFolder()

    private func reload(_ data: Persisted) -> Persisted {
        let state = FileStateStore(base: base, delay: 3600)
        let history = FileHistoryStore(base: base, calendar: .current, delay: 3600)
        state.savePrefs(data.prefs)
        state.saveLive(data.live)
        data.events.forEach(history.append)
        state.flush()
        history.flush()
        var loaded = Persisted()
        loaded.prefs = FileStateStore(base: base, delay: 3600).loadPrefs()
        loaded.live = FileStateStore(base: base, delay: 3600).loadLive()
        loaded.events = FileHistoryStore(base: base, calendar: .current, delay: 3600)
            .events(from: day(2026, 3, 1), to: day(2026, 4, 1))
        return loaded
    }

    @Test func doneInTheSameSecondAsAResetGivesTheSameStreakAfterReload() {
        let h = EngineHarness(at: day(2026, 3, 4, 10).addingTimeInterval(0.2)) { $0.prefs.water.dailyGoalGlasses = 1 }
        h.engine.emergencySkip(.water)
        h.clock.advance(minutes: 0.5 / 60)
        h.engine.logWater(1)
        let stats = Stats()
        let before = stats.streak(.water, data: h.engine.data, now: h.clock.now)
        let after = stats.streak(.water, data: reload(h.engine.data), now: h.clock.now)
        #expect(before == after)
        #expect(before == 0)
    }
}
