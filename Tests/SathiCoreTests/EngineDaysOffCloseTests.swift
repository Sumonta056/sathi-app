import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine days off close")
struct EngineDaysOffCloseTests {
    private var today: DayKey { DayKey(day(2026, 3, 4), calendar: .current) }
    private var allButWednesday: Set<Weekday> { Set(Weekday.allCases).subtracting([.wednesday]) }

    private func showedSnoozedNote(_ h: EngineHarness) -> Bool {
        h.presenter.calls.contains { call in
            if case .showSnoozed = call { return true }
            return false
        }
    }

    @Test func todayOffClearsTheSnoozeAndMovesToTomorrow() {
        let h = EngineHarness()
        h.showReminder(.water)
        h.engine.snooze(.water)
        h.advance(minutes: 5)
        #expect(h.engine.phase(.water) == .bubble(.persist))
        let events = h.history.appended.count
        h.engine.data.prefs.water.daysOff = [today]
        #expect(h.engine.phase(.water) == .idle)
        #expect(h.history.appended.count == events)
        #expect(h.engine.state(.water).snoozes == 0)
        #expect(h.engine.state(.water).snoozedUntil == nil)
        #expect(h.engine.state(.water).nextDue == day(2026, 3, 5, 9, 30))
        #expect(!showedSnoozedNote(h))
    }

    @Test func todayOffClosesTheWaterLock() {
        let h = EngineHarness()
        h.showReminder(.water)
        h.engine.snooze(.water)
        h.advance(minutes: 5)
        h.engine.snooze(.water)
        h.advance(minutes: 5)
        #expect(h.engine.phase(.water) == .lock)
        let events = h.history.appended.count
        h.engine.data.prefs.water.daysOff = [today]
        #expect(h.engine.phase(.water) == .idle)
        #expect(h.presenter.calls.contains(.closeLock))
        #expect(h.history.appended.count == events)
        #expect(h.engine.state(.water).snoozes == 0)
    }

    @Test func todayWeekdayOffClosesTheReadingCornerPopup() {
        let h = EngineHarness()
        h.showReminder(.reading)
        #expect(h.engine.isActive(.reading))
        let events = h.history.appended.count
        h.engine.data.prefs.reading.weekdays = allButWednesday
        #expect(h.engine.phase(.reading) == .idle)
        #expect(h.presenter.calls.contains(.closeBubble(.reading)))
        #expect(h.history.appended.count == events)
        #expect(!showedSnoozedNote(h))
    }

    @Test func todayOffClosesTheGymCornerPopup() {
        let h = EngineHarness { $0.prefs.gym.enabled = true }
        h.showReminder(.gym)
        #expect(h.engine.isActive(.gym))
        let events = h.history.appended.count
        h.engine.data.prefs.gym.daysOff = [today]
        #expect(h.engine.phase(.gym) == .idle)
        #expect(h.presenter.calls.contains(.closeBubble(.gym)))
        #expect(h.history.appended.count == events)
        #expect(h.engine.state(.gym).snoozes == 0)
    }

    @Test func anotherHabitsChangeKeepsAReminderShownOnADayOff() {
        let h = EngineHarness { $0.prefs.water.daysOff = [today] }
        h.showReminder(.water)
        #expect(h.engine.phase(.water) == .bubble(.nudge))
        h.engine.data.prefs.reading.weekdays = Set(Weekday.allCases).subtracting([.friday])
        #expect(h.engine.phase(.water) == .bubble(.nudge))
        #expect(!h.presenter.calls.contains(.closeBubble(.water)))
    }

    @Test func ownChangeKeepsAReminderShownOnADayOffWhenTodayWasAlreadyOff() {
        let h = EngineHarness { $0.prefs.water.daysOff = [today] }
        h.showReminder(.water)
        h.engine.data.prefs.water.intervalMinutes += 30
        #expect(h.engine.phase(.water) == .bubble(.nudge))
        #expect(!h.presenter.calls.contains(.closeBubble(.water)))
    }

    @Test func meditationTakesTheLockAfterWaterTurnsOffToday() {
        let start = day(2026, 3, 4, 15)
        let h = EngineHarness(at: start) {
            $0.prefs.meditation.enabled = true
            $0.prefs.meditation.strictness = .strict
            $0.live.lastWaterDone = start.addingTimeInterval(-Timing.minute)
        }
        h.showReminder(.water)
        h.showReminder(.meditation)
        h.engine.snooze(.water)
        h.engine.snooze(.meditation)
        h.advance(minutes: 5)
        h.engine.snooze(.water)
        h.engine.snooze(.meditation)
        h.advance(minutes: 5)
        #expect(h.engine.phase(.water) == .lock)
        #expect(h.engine.phase(.meditation) == .bubble(.persist))
        h.engine.data.prefs.water.daysOff = [today]
        #expect(h.engine.phase(.water) == .idle)
        #expect(h.presenter.calls.contains(.closeLock))
        #expect(h.engine.phase(.meditation) == .bubble(.persist))
        h.engine.snooze(.meditation)
        h.advance(minutes: 5)
        #expect(h.engine.phase(.meditation) == .lock)
        #expect(h.presenter.calls.last == .showLock(.meditation))
    }
}
