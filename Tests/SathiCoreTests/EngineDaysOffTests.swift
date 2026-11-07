import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine days off")
struct EngineDaysOffTests {
    private var today: DayKey { DayKey(day(2026, 3, 4), calendar: .current) }
    private var tomorrow: DayKey { DayKey(day(2026, 3, 5), calendar: .current) }
    private var allButWednesday: Set<Weekday> { Set(Weekday.allCases).subtracting([.wednesday]) }

    private func waterOnly(_ p: inout Persisted) {
        p.prefs.reading.enabled = false
        p.prefs.meditation.enabled = false
        p.prefs.gym.enabled = false
    }

    @Test func noWaterReminderOnADateOff() {
        let h = EngineHarness {
            $0.prefs.water.daysOff = [today]
        }
        h.advance(minutes: 8 * 60)
        #expect(!h.presenter.calls.contains(.showBubble(.water, .nudge)))
        #expect(h.engine.phase(.water) == .idle)
    }

    @Test func isOffTodayOnADateOff() {
        let h = EngineHarness { $0.prefs.water.daysOff = [today] }
        #expect(h.engine.isOffToday(.water))
        #expect(!h.engine.isOffToday(.reading))
    }

    @Test func isOffTodayOnAWeekdayOff() {
        let h = EngineHarness { $0.prefs.reading.weekdays = allButWednesday }
        #expect(h.engine.isOffToday(.reading))
        #expect(!h.engine.isOffToday(.water))
    }

    @Test func isNotOffTodayWhenOnlyTomorrowIsOff() {
        let h = EngineHarness { $0.prefs.gym.daysOff = [tomorrow] }
        #expect(!h.engine.isOffToday(.gym))
    }

    @Test func todayOffClosesOnlyThatBuddy() {
        let h = EngineHarness { $0.prefs.gym.enabled = true }
        h.showReminder(.water)
        h.showReminder(.gym)
        let gymPhase = h.engine.phase(.gym)
        let events = h.history.appended.count
        h.engine.data.prefs.water.daysOff = [today]
        #expect(h.engine.phase(.water) == .idle)
        #expect(h.presenter.calls.contains(.closeBubble(.water)))
        #expect(h.history.appended.count == events)
        #expect(gymPhase != .idle)
        #expect(h.engine.phase(.gym) == gymPhase)
        #expect(!h.presenter.calls.contains(.closeBubble(.gym)))
    }

    @Test func todayOffKeepsARunningSession() {
        let h = EngineHarness()
        h.engine.startReading()
        h.engine.data.prefs.reading.daysOff = [today]
        #expect(h.engine.phase(.reading) == .session)
        #expect(!h.presenter.calls.contains(.closeSession(.reading)))
    }

    @Test func pillSaysDayOff() {
        let h = EngineHarness { $0.prefs.water.daysOff = [today] }
        #expect(h.engine.pill(.water) == "Day off")
    }

    @Test func pillSaysDayOffOnAWeekdayOff() {
        let h = EngineHarness { $0.prefs.reading.weekdays = allButWednesday }
        #expect(h.engine.pill(.reading) == "Day off")
    }

    @Test func pillSaysOffBeforeDayOff() {
        let h = EngineHarness {
            $0.prefs.water.enabled = false
            $0.prefs.water.daysOff = [today]
        }
        #expect(h.engine.pill(.water) == "Off")
    }

    @Test func pillSaysPausedBeforeDayOff() {
        let h = EngineHarness { $0.prefs.water.daysOff = [today] }
        h.engine.pause()
        #expect(h.engine.pill(.water) == "Paused")
    }

    @Test func focusLeavesOutAHabitThatIsOffToday() {
        let h = EngineHarness {
            waterOnly(&$0)
            $0.prefs.water.daysOff = [today]
        }
        #expect(h.engine.focus == nil)
        #expect(h.engine.statusText == "Sathi")
    }

    @Test func focusPicksAnotherHabitOverOneThatIsOffToday() {
        let h = EngineHarness {
            $0.prefs.water.daysOff = [today]
            $0.events = [.done(.reading, 15, at: day(2026, 3, 4, 9))]
        }
        #expect(h.engine.focus == .reading)
    }

    @Test func showAReminderNowStillWorksOnADayOff() {
        let h = EngineHarness { $0.prefs.water.daysOff = [today] }
        h.showReminder(.water)
        #expect(h.engine.phase(.water) == .bubble(.nudge))
        #expect(h.presenter.calls.contains(.showBubble(.water, .nudge)))
        h.advance(minutes: 1)
        #expect(h.engine.phase(.water) == .bubble(.nudge))
    }

    @Test func dayOffEndsAtMidnight() {
        let h = EngineHarness { $0.prefs.water.daysOff = [today] }
        h.advance(minutes: day(2026, 3, 5, 9, 29).timeIntervalSince(h.clock.now) / 60)
        #expect(!h.presenter.calls.contains(.showBubble(.water, .nudge)))
        #expect(!h.engine.isOffToday(.water))
        h.advance(minutes: 1)
        #expect(h.engine.phase(.water) == .bubble(.nudge))
        #expect(h.presenter.calls.contains(.showBubble(.water, .nudge)))
    }

    @Test func addingByKeyAddsTheDayOnce() throws {
        let h = EngineHarness(at: day(2026, 11, 7, 10))
        let k = try #require(DayKey(raw: "2026-11-12"))
        h.engine.addDayOff(.water, key: k)
        #expect(h.store.prefs.water.daysOff == [k])
        let before = h.engine.data.prefs
        h.engine.addDayOff(.water, key: k)
        #expect(h.engine.data.prefs == before)
        #expect(h.store.prefs.water.daysOff == [k])
        #expect(h.store.prefs.gym.daysOff.isEmpty)
    }

    @Test func dayOffMonthMatchesTheHabitDaysResult() throws {
        let h = EngineHarness(at: day(2026, 11, 7, 10))
        try h.engine.addDayOff(.gym, key: #require(DayKey(raw: "2026-11-20")))
        let expected = h.engine.data.prefs.days(.gym).month(offset: 0, now: h.clock.now, calendar: Calendar.gregorian(in: h.engine.timeZone))
        #expect(h.engine.dayOffMonth(.gym, offset: 0) == expected)
        #expect(expected.weeks.flatMap { $0 }.compactMap { $0 }.contains { $0.state == .off })
    }
}
