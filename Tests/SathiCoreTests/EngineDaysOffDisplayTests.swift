import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine days off display")
struct EngineDaysOffDisplayTests {
    private func offKeys(from start: Date, count: Int) -> Set<DayKey> {
        Set((0 ..< count).map { DayKey(Calendar.current.date(byAdding: .day, value: $0, to: start)!, calendar: .current) })
    }

    @Test func pastDueWithNoActiveTimeAheadShowsNoReminder() {
        let h = EngineHarness(at: day(2026, 3, 4, 20)) {
            $0.prefs.reading.enabled = false
            $0.prefs.meditation.enabled = false
            $0.prefs.gym.enabled = false
            $0.live.lastWaterDone = day(2026, 3, 3, 17)
            $0.prefs.water.daysOff = offKeys(from: day(2026, 3, 5), count: Limits.daysOffMaxAhead + Limits.daysPerWeek + 1)
        }
        #expect(h.engine.state(.water).nextDue < h.clock.now)
        #expect(h.engine.pill(.water) == "No reminder")
        #expect(h.engine.focus == nil)
        #expect(h.engine.statusText == "Sathi")
    }

    @Test func readingSnoozeEndingOnTheWeekendWaitsForMondaysSetTime() {
        let h = EngineHarness(at: day(2026, 3, 6, 23, 50)) {
            $0.prefs.water.enabled = false
            $0.prefs.general.snoozeMinutes = 15
            $0.prefs.reading.weekdays = [.monday, .tuesday, .wednesday, .thursday, .friday]
        }
        #expect(h.engine.isActive(.reading))
        h.engine.snooze(.reading)
        #expect(h.engine.state(.reading).snoozedUntil == day(2026, 3, 9, 22))
        h.advance(minutes: day(2026, 3, 9, 21, 59).timeIntervalSince(h.clock.now) / 60)
        #expect(!h.engine.isActive(.reading))
        h.advance(minutes: 1)
        #expect(h.engine.isActive(.reading))
    }
}
