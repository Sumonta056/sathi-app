import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine history")
struct EngineHistoryTests {
    @Test func loggingAGlassAppendsOneDoneEvent() {
        let h = EngineHarness()
        h.engine.logWater(1)
        #expect(h.history.appended == [.done(.water, 1, at: day(2026, 3, 4, 10))])
        #expect(h.engine.data.events.last == .done(.water, 1, at: day(2026, 3, 4, 10)))
    }

    @Test func finishingASessionRecordsReadingMinutes() {
        let h = EngineHarness()
        h.engine.startReading()
        h.advance(minutes: 15)
        #expect(h.history.appended == [.done(.reading, 15, at: day(2026, 3, 4, 10, 15))])
    }

    @Test func ignoringABubbleRecordsOneSnooze() {
        let h = EngineHarness()
        h.showReminder(.water)
        h.advance(minutes: 5)
        #expect(h.history.appended == [.snooze(.water, at: day(2026, 3, 4, 10, 5))])
    }

    @Test func snoozeButtonRecordsASnooze() {
        let h = EngineHarness()
        h.showReminder(.water)
        h.engine.snooze()
        #expect(h.history.appended == [.snooze(.water, at: day(2026, 3, 4, 10))])
    }

    @Test func stoppingASessionRecordsAReadingSnooze() {
        let h = EngineHarness()
        h.engine.startReading()
        h.engine.stopSession()
        #expect(h.history.appended == [.snooze(.reading, at: day(2026, 3, 4, 10))])
    }

    @Test func emergencySkipRecordsASkip() {
        let h = EngineHarness()
        h.engine.emergencySkip(.water)
        #expect(h.history.appended == [.skip(.water, at: day(2026, 3, 4, 10))])
    }

    @Test func changingAPrefSavesPrefsAndNotLive() {
        let h = EngineHarness()
        let prefsBefore = h.store.prefsSaves
        let liveBefore = h.store.liveSaves
        h.engine.data.prefs.water.intervalMinutes = 30
        #expect(h.store.prefsSaves == prefsBefore + 1)
        #expect(h.store.liveSaves == liveBefore)
        #expect(h.store.prefs.water.intervalMinutes == 30)
    }

    @Test func loggingWaterSavesLiveAndNotPrefs() {
        let h = EngineHarness()
        let prefsBefore = h.store.prefsSaves
        let liveBefore = h.store.liveSaves
        h.engine.logWater(1)
        #expect(h.store.liveSaves > liveBefore)
        #expect(h.store.prefsSaves == prefsBefore)
        #expect(h.store.live.lastWaterDone == day(2026, 3, 4, 10))
    }

    @Test func initLoadsPrefsAndLiveFromTheStore() {
        let h = EngineHarness {
            $0.prefs.general.name = "Asha"
            $0.live.bottleLevel = 0.5
        }
        #expect(h.engine.data.prefs.general.name == "Asha")
        #expect(h.engine.data.live.bottleLevel == 0.5)
    }

    @Test func initLoadsOnlyEventsInsideTheThreeMonthWindow() {
        let tooOld = HistoryEvent.done(.water, 1, at: day(2025, 12, 31, 23, 59))
        let windowStart = HistoryEvent.done(.water, 2, at: day(2026, 1, 1))
        let recent = HistoryEvent.snooze(.reading, at: day(2026, 3, 4, 9))
        let h = EngineHarness { $0.events = [tooOld, windowStart, recent] }
        #expect(h.engine.data.events == [windowStart, recent])
    }

    @Test func recordingDropsEventsThatLeftTheWindow() {
        let old = HistoryEvent.done(.water, 1, at: day(2026, 1, 15, 10))
        let kept = HistoryEvent.done(.water, 1, at: day(2026, 2, 15, 10))
        let h = EngineHarness(at: day(2026, 3, 31, 23)) { $0.events = [old, kept] }
        #expect(h.engine.data.events == [old, kept])
        h.clock.advance(minutes: 11 * 60)
        h.engine.logWater(1)
        #expect(h.engine.data.events == [kept, .done(.water, 1, at: day(2026, 4, 1, 10))])
        #expect(h.history.events.contains(old))
    }

    @Test func historyIsKeptWhenAHabitIsTurnedOff() {
        let h = EngineHarness()
        h.engine.logWater(1)
        h.engine.data.prefs.water.enabled = false
        #expect(h.engine.data.events == [.done(.water, 1, at: day(2026, 3, 4, 10))])
    }
}
