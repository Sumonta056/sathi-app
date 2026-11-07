import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine session restore")
struct EngineSessionRestoreTests {
    private let t0 = day(2026, 3, 4, 8)

    private func started() -> EngineHarness {
        let h = EngineHarness(at: t0) {
            $0.prefs.water.enabled = false
            $0.prefs.reading.enabled = false
            $0.prefs.gym.enabled = false
            $0.prefs.meditation.enabled = true
            $0.prefs.meditation.sessionMinutes = 5
        }
        h.engine.startMeditation()
        h.advance(minutes: 2)
        return h
    }

    private func restart(_ h: EngineHarness, at date: Date) -> EngineHarness {
        let again = EngineHarness.restarted(from: h, at: date)
        again.engine.start()
        again.engine.stop()
        return again
    }

    @Test func pauseIsSaved() throws {
        let h = started()
        h.engine.pauseSession(.meditation)
        let saved = try #require(h.store.live.meditationSession)
        #expect(saved.pausedAt == t0.addingTimeInterval(2 * Timing.minute))
    }

    @Test func pausedSessionComesBackPausedTheSameDay() throws {
        let h = started()
        h.engine.pauseSession(.meditation)
        let again = restart(h, at: t0.addingTimeInterval(30 * Timing.minute))
        let s = try #require(again.engine.session(.meditation))
        #expect(s.isPaused)
        #expect(s.left(at: again.clock.now) == 3 * Timing.minute)
        #expect(again.presenter.calls.contains(.showSession(.meditation)))
    }

    @Test func pausedSessionIsDroppedTheNextDay() {
        let h = started()
        h.engine.pauseSession(.meditation)
        let again = restart(h, at: day(2026, 3, 5, 8))
        #expect(again.engine.session(.meditation) == nil)
        #expect(again.store.live.meditationSession == nil)
        #expect(again.history.appended.isEmpty)
    }

    @Test func runningSessionWithTimeLeftComesBackRunning() throws {
        let h = started()
        let again = restart(h, at: t0.addingTimeInterval(4 * Timing.minute))
        let s = try #require(again.engine.session(.meditation))
        #expect(!s.isPaused)
        #expect(s.end == t0.addingTimeInterval(5 * Timing.minute))
        #expect(again.presenter.calls.contains(.showSession(.meditation)))
    }

    @Test func runningSessionPastItsEndIsDropped() {
        let h = started()
        let again = restart(h, at: t0.addingTimeInterval(10 * Timing.minute))
        #expect(again.engine.session(.meditation) == nil)
        #expect(again.store.live.meditationSession == nil)
        #expect(again.history.appended.isEmpty)
    }

    private func restart(_ h: EngineHarness, changing change: @escaping (inout Persisted) -> Void) -> EngineHarness {
        let again = EngineHarness.quiet(at: h.clock.now) {
            $0.prefs = h.store.prefs
            $0.live = h.store.live
            change(&$0)
        }
        again.engine.start()
        again.engine.stop()
        return again
    }

    @Test func pausedSessionIsDroppedWhenMeditationIsTurnedOff() {
        let h = started()
        h.engine.pauseSession(.meditation)
        let again = restart(h) { $0.prefs.meditation.enabled = false }
        #expect(again.engine.session(.meditation) == nil)
        #expect(again.store.live.meditationSession == nil)
        #expect(again.history.appended.isEmpty)
    }

    @Test func pausedSessionIsDroppedOnADayOff() throws {
        let h = started()
        h.engine.pauseSession(.meditation)
        let today = try #require(DayKey(raw: "2026-03-04"))
        let again = restart(h) { $0.prefs.meditation.daysOff = [today] }
        #expect(again.engine.session(.meditation) == nil)
        #expect(again.store.live.meditationSession == nil)
        #expect(again.history.appended.isEmpty)
    }

    @Test func finishClearsTheSavedSession() {
        let h = started()
        #expect(h.store.live.meditationSession != nil)
        h.advance(minutes: 3)
        #expect(h.store.live.meditationSession == nil)
    }
}
