import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine meditation")
struct EngineMeditationTests {
    private func harness(at start: Date, configure: (inout Persisted) -> Void = { _ in }) -> EngineHarness {
        EngineHarness(at: start) {
            $0.prefs.meditation.enabled = true
            $0.live.lastWaterDone = start.addingTimeInterval(-Timing.minute)
            configure(&$0)
        }
    }

    private func doneEvents(_ h: EngineHarness) -> [HistoryEvent] {
        h.history.appended.filter { $0.kind == .done }
    }

    @Test func enabledMeditationBecomesDueAtTheMorningSlot() {
        let h = harness(at: day(2026, 3, 4, 7))
        #expect(h.engine.state(.meditation).nextDue == day(2026, 3, 4, 8))
        h.advance(minutes: 59)
        #expect(h.engine.phase == .idle)
        h.advance(minutes: 1)
        #expect(h.engine.phase == .bubble(.meditation, .nudge))
        #expect(h.presenter.calls.last == .showBubble(.meditation, .nudge))
        #expect(h.sound.played.last == .tink)
    }

    @Test func launchAfterAMissedSlotShowsTheBubbleNow() {
        let h = harness(at: day(2026, 3, 4, 15))
        #expect(h.engine.phase == .bubble(.meditation, .nudge))
    }

    @Test func meditationSessionRecordsOneDoneEventAndCelebrates() {
        let h = harness(at: day(2026, 3, 4, 15))
        h.engine.startMeditation()
        #expect(h.engine.phase == .session(.meditation))
        #expect(h.presenter.calls.last == .showSession)
        h.advance(minutes: 4)
        #expect(h.engine.phase == .session(.meditation))
        #expect(doneEvents(h).isEmpty)
        h.advance(minutes: 1)
        #expect(doneEvents(h) == [.done(.meditation, 5, at: day(2026, 3, 4, 15, 5))])
        #expect(h.engine.phase == .celebrate)
        #expect(h.engine.celebration.id == .meditation)
        #expect(h.engine.celebration.amount == 5)
        #expect(h.presenter.calls.contains(.showCelebration))
        #expect(h.engine.state(.meditation).nextDue == day(2026, 3, 4, 21, 30))
    }

    @Test(arguments: [2, 5, 10])
    func sessionLastsTheChosenLength(_ minutes: Int) {
        let h = harness(at: day(2026, 3, 4, 7)) { $0.prefs.meditation.sessionMinutes = minutes }
        h.engine.startMeditation()
        h.advance(minutes: Double(minutes) - 0.5)
        #expect(h.engine.phase == .session(.meditation))
        h.advance(minutes: 0.5)
        #expect(doneEvents(h).map(\.amount) == [Double(minutes)])
    }

    @Test func stoppingEarlyFromADueReminderRecordsASnooze() {
        let h = harness(at: day(2026, 3, 4, 7))
        h.showReminder(.meditation)
        h.engine.startMeditation()
        h.advance(minutes: 2)
        h.engine.stopSession()
        #expect(h.engine.phase == .idle)
        #expect(h.engine.state(.meditation).snoozes == 1)
        #expect(h.history.appended == [.snooze(.meditation, at: day(2026, 3, 4, 7, 2))])
        #expect(h.presenter.calls.contains(.closeSession))
    }

    @Test func waterWaitsInTheQueueDuringAMeditationSession() {
        let h = harness(at: day(2026, 3, 4, 11, 57)) {
            $0.live.lastWaterDone = day(2026, 3, 4, 10)
            $0.events = [.done(.meditation, 5, at: day(2026, 3, 4, 8, 5))]
        }
        #expect(h.engine.phase == .idle)
        h.engine.startMeditation()
        h.advance(minutes: 3)
        #expect(h.engine.queue == [.water])
        #expect(h.engine.phase == .session(.meditation))
        #expect(!h.presenter.calls.contains(.showBubble(.water, .nudge)))
        h.advance(minutes: 2)
        h.engine.endCelebrate()
        h.engine.tick()
        #expect(h.engine.phase == .bubble(.water, .nudge))
    }

    @Test func strictStoredForMeditationNeverLocks() {
        let h = harness(at: day(2026, 3, 4, 15)) { $0.prefs.meditation.strictness = .strict }
        #expect(h.engine.phase == .bubble(.meditation, .nudge))
        h.engine.snooze()
        h.advance(minutes: 5)
        #expect(h.engine.phase == .bubble(.meditation, .persist))
        h.engine.snooze()
        h.advance(minutes: 5)
        #expect(h.engine.phase == .bubble(.meditation, .persist))
        #expect(!h.presenter.calls.contains(.showLock(.meditation)))
        #expect(!h.engine.lockIsNext(.meditation))
    }

    @Test func strictStoredForReadingNeverLocks() {
        let h = EngineHarness { $0.prefs.reading.strictness = .strict }
        h.showReminder(.reading)
        h.engine.snooze()
        h.advance(minutes: 5)
        h.engine.snooze()
        h.advance(minutes: 5)
        #expect(h.engine.phase == .bubble(.reading, .persist))
        #expect(!h.presenter.calls.contains(.showLock(.reading)))
    }

    @Test func meditationIsOffByDefaultAndNeverBecomesDue() {
        let h = EngineHarness(at: day(2026, 3, 4, 7)) { $0.live.lastWaterDone = day(2026, 3, 4, 6, 59) }
        for _ in 0 ..< 48 {
            h.advance(minutes: 30)
            #expect(!h.engine.isDue(.meditation))
        }
        h.showReminder(.meditation)
        #expect(!h.presenter.calls.contains(.showBubble(.meditation, .nudge)))
        #expect(!h.history.appended.contains { $0.habit == .meditation })
        #expect(h.engine.pill(.meditation) == "Off")
    }

    @Test func startSessionForWaterBeepsAndDoesNothing() {
        let h = harness(at: day(2026, 3, 4, 7))
        h.engine.startSession(.water)
        #expect(h.engine.phase == .idle)
        #expect(h.sound.beeps == 1)
        #expect(!h.presenter.calls.contains(.showSession))
    }

    @Test func startSessionForReadingAndMeditation() {
        let h = harness(at: day(2026, 3, 4, 7))
        h.engine.startSession(.reading)
        #expect(h.engine.phase == .session(.reading))
        h.engine.stopSession()
        h.engine.startSession(.meditation)
        #expect(h.engine.phase == .session(.meditation))
    }

    @Test func startMeditationIsRefusedDuringAnotherReminder() {
        let h = harness(at: day(2026, 3, 4, 7))
        h.showReminder(.water)
        h.engine.startMeditation()
        #expect(h.engine.phase == .bubble(.water, .nudge))
        #expect(h.sound.beeps == 1)
    }

    @Test func lockConfirmedForMeditationStartsASession() {
        let h = harness(at: day(2026, 3, 4, 7))
        h.engine.lockConfirmed(.meditation)
        #expect(h.engine.phase == .session(.meditation))
    }
}
