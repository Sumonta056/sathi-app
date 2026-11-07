import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine session pause")
struct EngineSessionPauseTests {
    private func harness(at start: Date = day(2026, 3, 4, 8), configure: (inout Persisted) -> Void = { _ in }) -> EngineHarness {
        EngineHarness(at: start) {
            $0.prefs.water.enabled = false
            $0.prefs.reading.enabled = false
            $0.prefs.gym.enabled = false
            $0.prefs.meditation.enabled = true
            $0.prefs.meditation.sessionMinutes = 5
            configure(&$0)
        }
    }

    @Test func pausedSessionStaysActiveAndKeepsItsTimeLeft() throws {
        let h = harness()
        h.engine.startMeditation()
        h.advance(minutes: 1)
        h.engine.pauseSession(.meditation)
        let left = try #require(h.engine.session(.meditation)).left(at: h.clock.now)
        h.advance(minutes: 3)
        let s = try #require(h.engine.session(.meditation))
        #expect(s.isPaused)
        #expect(s.left(at: h.clock.now) == left)
    }

    @Test func resumedSessionFinishesLaterByThePausedLength() {
        let h = harness()
        h.engine.startMeditation()
        h.advance(minutes: 2)
        h.engine.pauseSession(.meditation)
        h.advance(minutes: 3)
        #expect(h.engine.phase(.meditation) == .session)
        #expect(h.history.appended.isEmpty)
        h.engine.resumeSession(.meditation)
        h.advance(minutes: 2.5)
        #expect(h.history.appended.isEmpty)
        h.advance(minutes: 2.5)
        #expect(h.history.appended == [.done(.meditation, 5, at: day(2026, 3, 4, 8, 10))])
    }

    @Test func stopWhilePausedWithNothingDueLeavesNoTrace() {
        let h = harness()
        let due = h.engine.state(.meditation).nextDue
        h.engine.startMeditation()
        h.engine.pauseSession(.meditation)
        h.advance(minutes: 1)
        h.engine.stopSession(.meditation)
        #expect(h.engine.activities.isEmpty)
        #expect(h.history.appended.isEmpty)
        #expect(h.engine.state(.meditation).snoozedUntil == nil)
        #expect(h.engine.state(.meditation).nextDue == due)
    }

    @Test func stopWhilePausedFromAReminderSnoozesOnce() {
        let h = harness()
        h.showReminder(.meditation)
        #expect(h.engine.phase(.meditation) == .bubble(.nudge))
        h.engine.startMeditation()
        h.engine.pauseSession(.meditation)
        h.advance(minutes: 1)
        h.engine.stopSession(.meditation)
        #expect(h.history.appended.filter { $0.kind == .snooze }.count == 1)
        #expect(h.engine.state(.meditation).snoozes == 1)
    }

    @Test func pausedSessionEndsAtMidnightWithoutCounting() {
        let h = harness(at: day(2026, 3, 4, 23, 45))
        let due = h.engine.state(.meditation).nextDue
        h.engine.startMeditation()
        h.advance(minutes: 5 - 0.5)
        h.engine.pauseSession(.meditation)
        h.advance(minutes: 11.5)
        #expect(h.engine.phase(.meditation) == .idle)
        #expect(h.history.appended.isEmpty)
        #expect(h.engine.state(.meditation).snoozedUntil == nil)
        #expect(h.engine.state(.meditation).nextDue == due)
        #expect(h.presenter.calls.contains(.closeSession(.meditation)))
    }

    @Test func otherBuddiesStillRemindDuringAPause() {
        let start = day(2026, 3, 4, 10)
        let h = harness(at: start) {
            $0.prefs.water.enabled = true
            $0.live.lastWaterDone = start.addingTimeInterval(-110 * Timing.minute)
        }
        h.engine.startMeditation()
        h.engine.pauseSession(.meditation)
        h.advance(minutes: 15)
        #expect(h.presenter.calls.contains { call in
            if case .showBubble(.water, _) = call { return true }
            return false
        })
    }

    @Test func statusTextIsFrozenWhilePaused() {
        let h = harness()
        h.engine.startMeditation()
        h.advance(minutes: 1)
        h.engine.pauseSession(.meditation)
        h.advance(minutes: 1)
        #expect(h.engine.statusText == "4:00")
        h.advance(minutes: 2)
        #expect(h.engine.statusText == "4:00")
    }

    @Test func pausedSessionDoesNotTickEverySecond() {
        let h = harness()
        h.engine.startMeditation()
        #expect(h.engine.nextTickDelay() == Timing.activeTick)
        h.engine.pauseSession(.meditation)
        #expect(h.engine.nextTickDelay() != Timing.activeTick)
    }
}
