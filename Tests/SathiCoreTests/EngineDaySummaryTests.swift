import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine day summary")
struct EngineDaySummaryTests {
    private var today: DayKey { DayKey(day(2026, 3, 4), calendar: .current) }
    private var yesterday: DayKey { DayKey(day(2026, 3, 3), calendar: .current) }
    private var tomorrow: DayKey { DayKey(day(2026, 3, 5), calendar: .current) }

    private func allOff(_ p: inout Persisted) {
        p.prefs.water.enabled = false
        p.prefs.reading.enabled = false
        p.prefs.meditation.enabled = false
        p.prefs.gym.enabled = false
    }

    private func shows(_ h: EngineHarness) -> Int {
        h.presenter.calls.filter { $0 == .showDaySummary }.count
    }

    @Test func notShownBeforeTheTime() {
        let h = EngineHarness(at: day(2026, 3, 4, 21, 59), configure: allOff)
        #expect(shows(h) == 0)
        #expect(h.engine.data.live.lastDaySummary == nil)
    }

    @Test func shownOnceAtTheTimeAndRemembered() {
        let h = EngineHarness(at: day(2026, 3, 4, 21, 59), configure: allOff)
        h.advance(minutes: 1)
        #expect(shows(h) == 1)
        #expect(h.engine.data.live.lastDaySummary == today)
        #expect(h.store.live.lastDaySummary == today)
    }

    @Test func aLaterTickTheSameDayDoesNotShowAgain() {
        let h = EngineHarness(at: day(2026, 3, 4, 21, 59), configure: allOff)
        h.advance(minutes: 1)
        h.advance(minutes: 30)
        h.advance(minutes: 60)
        #expect(shows(h) == 1)
    }

    @Test func itShowsAgainTheNextEvening() {
        let h = EngineHarness(at: day(2026, 3, 4, 21, 59), configure: allOff)
        h.advance(minutes: 1)
        h.advance(minutes: 24 * 60)
        #expect(shows(h) == 2)
        #expect(h.engine.data.live.lastDaySummary == tomorrow)
    }

    @Test func aRelaunchAfterItShowedTodayDoesNotShowAgain() {
        let h = EngineHarness(at: day(2026, 3, 4, 22, 30)) {
            allOff(&$0)
            $0.live.lastDaySummary = today
        }
        h.advance(minutes: 10)
        #expect(shows(h) == 0)
    }

    @Test func aRelaunchAfterAMissedTimeShowsIt() {
        let h = EngineHarness(at: day(2026, 3, 4, 23)) {
            allOff(&$0)
            $0.live.lastDaySummary = yesterday
        }
        #expect(shows(h) == 1)
        #expect(h.engine.data.live.lastDaySummary == today)
    }

    @Test func aRelaunchAfterAMissedTimeWithNoRecordShowsIt() {
        let h = EngineHarness(at: day(2026, 3, 4, 23, 45), configure: allOff)
        #expect(shows(h) == 1)
    }

    @Test func afterMidnightItNeverShowsForTheDayBefore() {
        let h = EngineHarness(at: day(2026, 3, 5, 0, 30)) {
            allOff(&$0)
            $0.live.lastDaySummary = yesterday
        }
        h.advance(minutes: 60)
        #expect(shows(h) == 0)
        #expect(h.engine.data.live.lastDaySummary == yesterday)
    }

    @Test func aMacAsleepPastMidnightSkipsTheDayBefore() {
        let h = EngineHarness(at: day(2026, 3, 4, 21), configure: allOff)
        h.advance(minutes: 3 * 60 + 30)
        #expect(shows(h) == 0)
    }

    @Test func aPauseDoesNotStopIt() {
        let h = EngineHarness(at: day(2026, 3, 4, 21), configure: allOff)
        h.engine.pause(hours: 3)
        h.advance(minutes: 60)
        #expect(h.engine.pausedUntil != nil)
        #expect(shows(h) == 1)
    }

    @Test func restOfDayDoesNotStopIt() {
        let h = EngineHarness(at: day(2026, 3, 4, 21), configure: allOff)
        h.engine.pauseRestOfDay()
        h.advance(minutes: 60)
        #expect(shows(h) == 1)
    }

    @Test func notShownWhenSwitchedOff() {
        let h = EngineHarness(at: day(2026, 3, 4, 21, 59)) {
            allOff(&$0)
            $0.prefs.general.daySummaryOn = false
        }
        h.advance(minutes: 1)
        h.advance(minutes: 60)
        #expect(shows(h) == 0)
        #expect(h.engine.data.live.lastDaySummary == nil)
    }

    @Test func switchedOnAfterTheTimeShowsAtTheNextTick() {
        let h = EngineHarness(at: day(2026, 3, 4, 23)) {
            allOff(&$0)
            $0.prefs.general.daySummaryOn = false
        }
        #expect(shows(h) == 0)
        h.engine.data.prefs.general.daySummaryOn = true
        h.advance(minutes: 1)
        #expect(shows(h) == 1)
    }

    @Test func aTimeMovedBeforeNowShowsAtTheNextTick() {
        let h = EngineHarness(at: day(2026, 3, 4, 21), configure: allOff)
        #expect(shows(h) == 0)
        h.engine.data.prefs.general.daySummaryMinutes = 20 * 60
        h.advance(minutes: 1)
        #expect(shows(h) == 1)
    }

    @Test func aLaterTimeWaitsForIt() {
        let h = EngineHarness(at: day(2026, 3, 4, 21, 59)) {
            allOff(&$0)
            $0.prefs.general.daySummaryMinutes = 23 * 60
        }
        h.advance(minutes: 1)
        #expect(shows(h) == 0)
        h.advance(minutes: 60)
        #expect(shows(h) == 1)
    }

    @Test func theNextTickIsPlannedForTheSummaryTime() {
        let h = EngineHarness(at: day(2026, 3, 4, 21, 59).addingTimeInterval(30), configure: allOff)
        #expect(h.engine.nextTickDelay() <= 30)
        h.clock.advance(minutes: 0.5)
        h.engine.tick()
        #expect(shows(h) == 1)
    }

    @Test func itMakesNoSoundAndNoHistoryEvent() {
        let h = EngineHarness(at: day(2026, 3, 4, 21, 59), configure: allOff)
        h.advance(minutes: 1)
        #expect(shows(h) == 1)
        #expect(h.sound.played.isEmpty)
        #expect(h.sound.beeps == 0)
        #expect(h.history.appended.isEmpty)
    }

    @Test func itShowsBesideAReminderWithoutChangingIt() {
        let h = EngineHarness(at: day(2026, 3, 4, 21, 59))
        h.advance(minutes: 1)
        #expect(shows(h) == 1)
        #expect(h.engine.phase(.reading) != .idle)
    }

    @Test func closeSendsCloseToThePresenter() {
        let h = EngineHarness(at: day(2026, 3, 4, 21, 59), configure: allOff)
        h.advance(minutes: 1)
        h.engine.closeDaySummary()
        #expect(h.presenter.calls.last == .closeDaySummary)
        #expect(h.engine.data.live.lastDaySummary == today)
    }
}
