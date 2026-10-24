import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine flows")
struct EngineFlowTests {
    @Test func waterBecomesDueAfterTheInterval() {
        let h = EngineHarness()
        h.advance(minutes: 119)
        #expect(h.engine.phase == .idle)
        h.advance(minutes: 1)
        #expect(h.engine.phase == .bubble(.water, .nudge))
        #expect(h.presenter.calls.last == .showBubble(.water, .nudge))
        #expect(h.sound.played.last == .glass)
    }

    @Test func strictWaterEscalatesToLock() {
        let h = EngineHarness()
        h.showReminder(.water)
        #expect(h.engine.phase == .bubble(.water, .nudge))

        h.engine.snooze()
        h.advance(minutes: 5)
        #expect(h.engine.phase == .bubble(.water, .persist))

        h.engine.snooze()
        h.advance(minutes: 5)
        #expect(h.engine.phase == .lock(.water))
        #expect(h.presenter.calls.last == .showLock(.water))
    }

    @Test func ignoringTheBubbleCountsAsASnooze() {
        let h = EngineHarness()
        h.showReminder(.water)
        h.advance(minutes: 5)
        #expect(h.engine.phase == .idle)
        #expect(h.engine.state(.water).snoozes == 1)
        #expect(h.presenter.calls.contains(.closeBubble))
    }

    @Test func confirmingTheLockLogsAGlass() {
        let h = EngineHarness { $0.prefs.general.soundOn = false }
        h.showReminder(.water)
        h.engine.snooze(); h.advance(minutes: 5)
        h.engine.snooze(); h.advance(minutes: 5)
        h.engine.lockConfirmed(.water)
        #expect(h.engine.data.events.last?.amount == 1)
        #expect(h.engine.phase == .celebrate)
        #expect(h.engine.state(.water).snoozes == 0)
        #expect(h.presenter.calls.contains(.closeLock))
        #expect(h.sound.played.isEmpty)
    }

    @Test func emergencySkipResetsTheStreak() {
        let h = EngineHarness { $0.events = [.done(.water, 8, at: day(2026, 3, 3, 10))] }
        #expect(h.engine.streak(.water) == 1)
        h.engine.emergencySkip(.water)
        #expect(h.engine.streak(.water) == 0)
        #expect(h.engine.phase == .idle)
    }

    @Test func readingSessionCompletes() {
        let h = EngineHarness()
        h.engine.startReading()
        #expect(h.engine.phase == .session(.reading))
        h.advance(minutes: 15)
        #expect(h.engine.data.events.last?.amount == 15)
        #expect(h.engine.phase == .celebrate)
        #expect(h.engine.celebration.id == .reading)
    }

    @Test func stoppingASessionStartedFromADueReminderSnoozesReading() {
        let h = EngineHarness()
        h.showReminder(.reading)
        h.engine.startReading()
        h.engine.stopSession()
        #expect(h.engine.phase == .idle)
        #expect(h.engine.state(.reading).snoozes == 1)
        #expect(!h.engine.data.events.contains { $0.habit == .reading && $0.kind == .done })
    }

    @Test func waterWaitsInTheQueueDuringASession() {
        let h = EngineHarness(at: day(2026, 3, 4, 11, 50)) { $0.live.lastWaterDone = day(2026, 3, 4, 10) }
        h.engine.startReading()
        h.advance(minutes: 11)
        #expect(h.engine.queue == [.water])
        h.advance(minutes: 4)
        h.engine.endCelebrate()
        h.engine.tick()
        #expect(h.engine.phase == .bubble(.water, .nudge))
    }

    @Test func pauseHoldsRemindersUntilItEnds() {
        let h = EngineHarness()
        h.engine.pause(hours: 3)
        h.advance(minutes: 150)
        #expect(h.engine.phase == .idle)
        #expect(h.engine.statusText == "Paused")
        h.advance(minutes: 31)
        #expect(h.engine.phase == .bubble(.water, .nudge))
    }

    @Test func disablingAHabitDropsItFromTheQueue() {
        let h = EngineHarness(at: day(2026, 3, 4, 11, 50)) { $0.live.lastWaterDone = day(2026, 3, 4, 10) }
        h.engine.startReading()
        h.advance(minutes: 11)
        #expect(h.engine.queue == [.water])
        h.engine.data.prefs.water.enabled = false
        #expect(h.engine.queue.isEmpty)
    }

    @Test func everyDataChangeIsSaved() {
        let h = EngineHarness()
        h.engine.logWater(1)
        #expect(h.history.appended.count == 1)
        #expect(h.store.live.lastWaterDone == day(2026, 3, 4, 10))
    }

    @Test func logWaterRoundsToQuarterWithMinimum() {
        let h = EngineHarness()
        h.engine.logWater(0.05)
        #expect(h.engine.data.events.last?.amount == 0.25)
        h.engine.logWater(1.3)
        #expect(h.engine.data.events.last?.amount == 1.25)
    }

    @Test func logBottleConvertsLevelToGlasses() {
        let h = EngineHarness()
        h.engine.logBottle(newLevel: 0.5)
        #expect(h.engine.data.live.bottleLevel == 0.5)
        #expect(h.engine.data.events.last?.amount == 1.5)
        h.engine.refillBottle()
        #expect(h.engine.data.live.bottleLevel == 1)
    }

    @Test func startReadingIsRefusedDuringAnotherReminder() {
        let h = EngineHarness()
        h.showReminder(.water)
        h.engine.startReading()
        #expect(h.engine.phase == .bubble(.water, .nudge))
        #expect(h.sound.beeps == 1)
    }

    @Test func openSettingsAsksThePresenter() {
        let h = EngineHarness()
        h.engine.openSettings()
        #expect(h.presenter.calls.last == .showSettings)
    }
}
