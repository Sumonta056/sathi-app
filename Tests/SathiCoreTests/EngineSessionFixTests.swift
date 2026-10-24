import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine session fixes")
struct EngineSessionFixTests {
    private func harness(at start: Date, configure: (inout Persisted) -> Void = { _ in }) -> EngineHarness {
        EngineHarness(at: start) {
            $0.prefs.meditation.enabled = true
            $0.live.lastWaterDone = start.addingTimeInterval(-Timing.minute)
            configure(&$0)
        }
    }

    @Test func stoppingAMenuStartedMeditationDoesNothing() {
        let h = harness(at: day(2026, 3, 4, 15)) { $0.events = [.done(.meditation, 5, at: day(2026, 3, 4, 8, 5))] }
        #expect(h.engine.phase == .idle)
        h.engine.startMeditation()
        h.advance(minutes: 2)
        h.engine.stopSession()
        #expect(h.engine.phase == .idle)
        #expect(h.history.appended.isEmpty)
        #expect(h.engine.state(.meditation).snoozes == 0)
        #expect(h.engine.state(.meditation).snoozedUntil == nil)
        h.advance(minutes: 8)
        #expect(h.engine.phase == .idle)
        #expect(!h.presenter.calls.contains(.showBubble(.meditation, .nudge)))
        #expect(h.engine.state(.meditation).nextDue == day(2026, 3, 4, 21, 30))
    }

    @Test func stoppingAMeditationStartedFromADueBubbleSnoozes() {
        let h = harness(at: day(2026, 3, 4, 15))
        #expect(h.engine.phase == .bubble(.meditation, .nudge))
        h.engine.startMeditation()
        h.engine.stopSession()
        #expect(h.history.appended == [.snooze(.meditation, at: day(2026, 3, 4, 15))])
        #expect(h.engine.state(.meditation).snoozes == 1)
    }

    @Test func stoppingAMenuStartedReadingDoesNothing() {
        let h = EngineHarness()
        h.engine.startReading()
        h.advance(minutes: 3)
        h.engine.stopSession()
        #expect(h.engine.phase == .idle)
        #expect(h.history.appended.isEmpty)
        #expect(h.engine.state(.reading).snoozes == 0)
        #expect(h.engine.state(.reading).snoozedUntil == nil)
        #expect(h.engine.state(.reading).nextDue == day(2026, 3, 4, 22))
    }

    @Test func stoppingAReadingStartedFromADueReminderSnoozes() {
        let h = EngineHarness()
        h.showReminder(.reading)
        h.engine.startReading()
        h.engine.stopSession()
        #expect(h.history.appended == [.snooze(.reading, at: day(2026, 3, 4, 10))])
        #expect(h.engine.state(.reading).snoozes == 1)
    }

    @Test func meditationStartPlaysNoSound() {
        let h = harness(at: day(2026, 3, 4, 7))
        h.engine.startMeditation()
        #expect(h.sound.played.isEmpty)
    }

    @Test func meditationFinishWithChimePlaysTinkNotHero() {
        let h = harness(at: day(2026, 3, 4, 7))
        h.engine.startMeditation()
        h.advance(minutes: 5)
        #expect(h.engine.phase == .celebrate)
        #expect(h.sound.played == [.tink])
    }

    @Test func meditationFinishWithoutChimeIsSilent() {
        let h = harness(at: day(2026, 3, 4, 7)) { $0.prefs.meditation.chime = false }
        h.engine.startMeditation()
        h.advance(minutes: 5)
        #expect(h.engine.phase == .celebrate)
        #expect(h.sound.played.isEmpty)
    }

    @Test func readingFinishStillPlaysHero() {
        let h = EngineHarness()
        h.engine.startReading()
        h.advance(minutes: 15)
        #expect(h.sound.played.last == .hero)
    }

    @Test func meditationDoneRecordsTheRealLengthAfterAPrefChange() {
        let h = harness(at: day(2026, 3, 4, 7)) { $0.prefs.meditation.sessionMinutes = 10 }
        h.engine.startMeditation()
        h.engine.data.prefs.meditation.sessionMinutes = 2
        h.advance(minutes: 10)
        #expect(h.history.appended.filter { $0.kind == .done } == [.done(.meditation, 10, at: day(2026, 3, 4, 7, 10))])
        #expect(h.engine.celebration.amount == 10)
    }

    @Test func readingDoneRecordsTheRealLengthAfterAPrefChange() {
        let h = EngineHarness()
        h.engine.startReading()
        h.engine.data.prefs.reading.sessionMinutes = 30
        h.advance(minutes: 15)
        #expect(h.history.appended.filter { $0.kind == .done } == [.done(.reading, 15, at: day(2026, 3, 4, 10, 15))])
    }
}
