import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine pause rest of day")
struct EnginePauseRestOfDayTests {
    private func bubbles(_ h: EngineHarness) -> Int {
        h.presenter.calls.filter { if case .showBubble = $0 { return true } else { return false } }.count
    }

    @Test func pausesUntilTheNextMidnight() {
        let h = EngineHarness(at: day(2026, 3, 4, 15))
        h.engine.pauseRestOfDay()
        #expect(h.engine.pausedUntil == day(2026, 3, 5))
    }

    @Test func pausesUntilLocalMidnightAfterTheDSTChange() {
        let zone = FixedZone.berlin
        let engine = Engine(
            store: InMemoryStateStore(),
            history: InMemoryHistoryStore(),
            clock: FakeClock(zone.date(2026, 3, 29, 15)),
            sound: SpySoundPlayer(),
            presenter: SpyPresenter(),
            calendar: zone.calendar
        )
        engine.pauseRestOfDay()
        let until = engine.pausedUntil
        #expect(until == zone.date(2026, 3, 30))
        #expect(until.map(zone.wallClock) == [2026, 3, 30, 0, 0])
    }

    @Test func noReminderShowsBeforeMidnight() {
        let h = EngineHarness(at: day(2026, 3, 4, 15)) {
            $0.prefs.reading.enabled = false
            $0.live.lastWaterDone = day(2026, 3, 4, 14, 30)
        }
        h.engine.pauseRestOfDay()
        h.advance(minutes: 120)
        h.advance(minutes: 6 * 60 + 59)
        #expect(h.engine.phase == .idle)
        #expect(bubbles(h) == 0)
        #expect(h.engine.statusText == "Paused")
    }

    @Test func dueHabitsShowAfterThePauseEnds() {
        let h = EngineHarness(at: day(2026, 3, 4, 15)) {
            $0.prefs.reading.enabled = false
            $0.live.lastWaterDone = day(2026, 3, 4, 14, 30)
        }
        h.engine.pauseRestOfDay()
        h.advance(minutes: 120)
        h.clock.now = day(2026, 3, 5, 10)
        h.engine.tick()
        #expect(h.engine.pausedUntil == nil)
        #expect(h.engine.phase == .bubble(.water, .nudge))
    }

    @Test func shortPauseIsHalfAnHour() {
        #expect(Timing.shortPauseHours == 0.5)
    }
}
