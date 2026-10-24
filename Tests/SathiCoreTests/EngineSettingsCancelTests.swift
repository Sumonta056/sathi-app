import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine settings cancel")
struct EngineSettingsCancelTests {
    private var allButWednesday: Set<Weekday> { Set(Weekday.allCases).subtracting([.wednesday]) }

    private func bubbles(_ id: HabitID, _ h: EngineHarness) -> Int {
        h.presenter.calls.filter { if case let .showBubble(shown, _) = $0 { return shown == id } else { return false } }.count
    }

    @Test func turningTodayOffDropsQueuedReading() {
        let h = EngineHarness(at: day(2026, 3, 4, 21, 59))
        h.showReminder(.water)
        h.advance(minutes: 1)
        #expect(h.engine.phase == .bubble(.water, .nudge))
        #expect(h.engine.queue == [.reading])
        h.engine.data.prefs.reading.weekdays = allButWednesday
        #expect(!h.engine.queue.contains(.reading))
        #expect(h.engine.state(.reading).nextDue == day(2026, 3, 5, 22))
        h.engine.logWater(1)
        h.engine.endCelebrate()
        h.engine.tick()
        h.advance(minutes: 60)
        #expect(bubbles(.reading, h) == 0)
    }

    @Test func turningTodayOffClearsTheReadingSnooze() {
        let h = EngineHarness(at: day(2026, 3, 4, 21, 59)) {
            $0.prefs.water.enabled = false
            $0.prefs.general.snoozeMinutes = 10
        }
        h.advance(minutes: 1)
        #expect(h.engine.phase == .bubble(.reading, .nudge))
        h.engine.snooze()
        #expect(h.engine.state(.reading).snoozedUntil == day(2026, 3, 4, 22, 10))
        h.engine.data.prefs.reading.weekdays = allButWednesday
        #expect(h.engine.state(.reading).snoozedUntil == nil)
        #expect(h.engine.state(.reading).nextDue == day(2026, 3, 5, 22))
        h.advance(minutes: 10)
        h.advance(minutes: 30)
        #expect(bubbles(.reading, h) == 1)
        #expect(h.engine.phase == .idle)
    }

    @Test func removingTheEveningSlotDropsQueuedMeditation() {
        let h = EngineHarness(at: day(2026, 3, 4, 21, 29)) {
            $0.prefs.reading.enabled = false
            $0.prefs.meditation.enabled = true
            $0.prefs.meditation.slots = [.morning, .evening]
            $0.events = [.done(.meditation, 5, at: day(2026, 3, 4, 8, 5))]
        }
        h.showReminder(.water)
        h.advance(minutes: 1)
        #expect(h.engine.phase == .bubble(.water, .nudge))
        #expect(h.engine.queue == [.meditation])
        h.engine.data.prefs.meditation.slots = [.morning]
        #expect(!h.engine.queue.contains(.meditation))
        #expect(h.engine.state(.meditation).nextDue == day(2026, 3, 5, 8))
    }

    @Test func aChangeThatKeepsTheHabitDueKeepsItQueued() {
        let h = EngineHarness(at: day(2026, 3, 4, 11, 50)) { $0.live.lastWaterDone = day(2026, 3, 4, 10) }
        h.engine.startReading()
        h.advance(minutes: 11)
        #expect(h.engine.queue == [.water])
        h.engine.data.prefs.water.intervalMinutes = 90
        #expect(h.engine.queue == [.water])
    }
}
