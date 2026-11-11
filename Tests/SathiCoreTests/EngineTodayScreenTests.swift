import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine Today screen")
struct EngineTodayScreenTests {
    private func only(_ p: inout Persisted, _ ids: HabitID...) {
        p.prefs.water.enabled = ids.contains(.water)
        p.prefs.reading.enabled = ids.contains(.reading)
        p.prefs.meditation.enabled = ids.contains(.meditation)
        p.prefs.gym.enabled = ids.contains(.gym)
    }

    private func buddy(_ h: EngineHarness, _ id: HabitID) -> TodayBuddy {
        h.engine.todayScreen.buddies.first { $0.habit == id }!
    }

    @Test func headerHasDateLineAndGreeting() {
        let h = EngineHarness(at: day(2026, 3, 4, 10, 30))
        let s = h.engine.todayScreen
        #expect(s.dateLine == "WEDNESDAY, 4 MARCH")
        #expect(s.greeting == h.engine.greeting)
    }

    @Test func buddiesComeInHabitOrder() {
        let h = EngineHarness()
        #expect(h.engine.todayScreen.buddies.map(\.habit) == HabitID.allCases)
    }

    @Test func runningActivityShowsMinutesAndNextAsk() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Code review", minutes: 30)
        h.advance(minutes: 12.5)
        guard case let .running(minutes, text, category, since, nextAsk) = h.engine.todayScreen.now else {
            Issue.record("not running")
            return
        }
        #expect(minutes == 12)
        #expect(text == "Code review")
        #expect(category == "Coding")
        #expect(since == wed(10))
        #expect(nextAsk == wed(10, 15))
    }

    @Test func trackerOnWithNothingRunningIsIdle() {
        let h = EngineHarness.tracker(at: wed(10))
        guard case .idle = h.engine.todayScreen.now else {
            Issue.record("not idle")
            return
        }
        #expect(h.engine.todayScreen.sofar.isOn)
    }

    @Test func trackerOffGivesOffNowAndNoSoFar() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.isOn = false }
        #expect(h.engine.todayScreen.now == .off)
        #expect(h.engine.todayScreen.sofar == .off)
    }

    @Test func soFarCountsTheRunningActivityAndTopCategories() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Code review", minutes: 60)
        h.advance(minutes: 45)
        let sofar = h.engine.todayScreen.sofar
        #expect(sofar.logged == 45 * 60)
        #expect(sofar.categories.map(\.name) == ["Coding"])
    }

    @Test func waterMetShowsMetAndLeavesComingUp() {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) {
            only(&$0, .water)
            $0.prefs.water.dailyGoalGlasses = 4
            $0.events = [.done(.water, 4, at: day(2026, 3, 4, 9))]
        }
        #expect(buddy(h, .water).status == .met)
        #expect(buddy(h, .water).unit == "glasses")
        #expect(buddy(h, .water).goal == 4)
        #expect(!h.engine.todayScreen.comingUp.contains { $0.kind == .habit(.water) })
    }

    @Test func waterNotMetShowsNextTimeAndComesUp() {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) {
            only(&$0, .water)
            $0.live.lastWaterDone = day(2026, 3, 4, 9, 30)
        }
        guard case let .next(due) = buddy(h, .water).status else {
            Issue.record("no next")
            return
        }
        #expect(due > h.clock.now)
        let item = h.engine.todayScreen.comingUp.first { $0.kind == .habit(.water) }
        #expect(item?.title == "Fota · water")
        #expect(item?.time == due)
    }

    @Test func dayOffShowsDayOffAndLeavesComingUp() {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) {
            only(&$0, .water)
            $0.prefs.water.daysOff = [DayKey(day(2026, 3, 4), calendar: .current)]
        }
        #expect(buddy(h, .water).status == .dayOff)
        #expect(!h.engine.todayScreen.comingUp.contains { $0.kind == .habit(.water) })
    }

    @Test func offBuddyShowsOff() {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) { only(&$0, .water) }
        #expect(buddy(h, .gym).status == .off)
    }

    @Test func gymShowsSessionNumberOfTotal() {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) {
            only(&$0, .gym)
            $0.prefs.gym.sessionsPerDay = 4
            $0.prefs.gym.sessionMinutes = 5
            $0.events = [.done(.gym, 5, at: day(2026, 3, 4, 9, 30))]
        }
        guard case let .gymSession(n, total, due) = buddy(h, .gym).status else {
            Issue.record("not a session")
            return
        }
        #expect(n == 2)
        #expect(total == 4)
        #expect(due > h.clock.now)
    }

    @Test func dueNowBuddyShowsDueNowAndLeavesComingUp() {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) {
            only(&$0, .water)
            $0.live.lastWaterDone = day(2026, 3, 4, 6)
        }
        h.showReminder(.water)
        #expect(buddy(h, .water).status == .dueNow)
        #expect(!h.engine.todayScreen.comingUp.contains { $0.kind == .habit(.water) })
    }

    @Test func pausedDayShowsPausedAndLeavesComingUp() {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) {
            only(&$0, .water)
            $0.live.lastWaterDone = day(2026, 3, 4, 9, 30)
        }
        h.engine.pause(hours: 2)
        #expect(buddy(h, .water).status == .paused)
        #expect(!h.engine.todayScreen.comingUp.contains { $0.kind == .habit(.water) })
    }

    @Test func snoozedBuddyShowsSnoozedAndStaysInComingUp() {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) {
            only(&$0, .water)
            $0.live.lastWaterDone = day(2026, 3, 4, 6)
        }
        h.showReminder(.water)
        h.engine.snooze(.water)
        guard case let .snoozed(until) = buddy(h, .water).status else {
            Issue.record("not snoozed")
            return
        }
        #expect(until > h.clock.now)
        #expect(h.engine.todayScreen.comingUp.contains { $0.kind == .habit(.water) && $0.time == until })
    }
}
