import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine day summary prefs")
struct EngineDaySummaryPrefsTests {
    private func quiet(_ p: inout Persisted) {
        p.prefs.water.enabled = false
        p.prefs.reading.enabled = false
    }

    private func closes(_ h: EngineHarness) -> Int {
        h.presenter.calls.filter { $0 == .closeDaySummary }.count
    }

    @Test func turningTheSwitchOffClosesTheOpenSummary() {
        let h = EngineHarness(at: day(2026, 3, 4, 22), configure: quiet)
        h.engine.data.prefs.general.daySummaryOn = false
        #expect(h.presenter.calls.last == .closeDaySummary)
    }

    @Test func turningTheSwitchOnDoesNotClose() {
        let h = EngineHarness(at: day(2026, 3, 4, 21)) {
            quiet(&$0)
            $0.prefs.general.daySummaryOn = false
        }
        h.engine.data.prefs.general.daySummaryOn = true
        #expect(closes(h) == 0)
    }

    @Test func movingTheTimeDoesNotClose() {
        let h = EngineHarness(at: day(2026, 3, 4, 22), configure: quiet)
        h.engine.data.prefs.general.daySummaryMinutes = 23 * 60
        #expect(closes(h) == 0)
    }

    @Test func changingTheSwitchPlansAnImmediateTick() {
        let h = EngineHarness(at: day(2026, 3, 4, 21), configure: quiet)
        h.engine.start()
        let before = h.engine.timer
        h.engine.data.prefs.general.daySummaryOn = false
        let after = h.engine.timer
        h.engine.stop()
        #expect(before != nil)
        #expect(after !== before)
    }

    @Test func changingTheTimePlansAnImmediateTick() {
        let h = EngineHarness(at: day(2026, 3, 4, 21), configure: quiet)
        h.engine.start()
        let before = h.engine.timer
        h.engine.data.prefs.general.daySummaryMinutes = 20 * 60
        let after = h.engine.timer
        h.engine.stop()
        #expect(after !== before)
    }

    @Test func anUnrelatedPrefChangePlansNoTick() {
        let h = EngineHarness(at: day(2026, 3, 4, 21), configure: quiet)
        h.engine.start()
        let before = h.engine.timer
        h.engine.data.prefs.general.name = "Asha"
        let after = h.engine.timer
        h.engine.stop()
        #expect(after === before)
    }
}
