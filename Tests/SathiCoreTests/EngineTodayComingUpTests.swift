import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine Today coming up")
struct EngineTodayComingUpTests {
    private func only(_ p: inout Persisted, _ ids: HabitID...) {
        p.prefs.water.enabled = ids.contains(.water)
        p.prefs.reading.enabled = ids.contains(.reading)
        p.prefs.meditation.enabled = ids.contains(.meditation)
        p.prefs.gym.enabled = ids.contains(.gym)
    }

    @Test func quickReminderDueTodayComesUpAndTomorrowDoesNot() {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) {
            only(&$0)
            $0.live.quickReminders = [
                QuickReminder(text: "Call Sam", due: day(2026, 3, 4, 15), createdAt: day(2026, 3, 4, 9)),
                QuickReminder(text: "Pay rent", due: day(2026, 3, 5, 9), createdAt: day(2026, 3, 4, 9))
            ]
        }
        let titles = h.engine.todayScreen.comingUp.map(\.title)
        #expect(titles.contains("Call Sam"))
        #expect(!titles.contains("Pay rent"))
    }

    @Test func daySummaryComesUpWhenOnAndNotShownToday() {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) { only(&$0) }
        let item = h.engine.todayScreen.comingUp.first { $0.kind == .daySummary }
        #expect(item?.title == "Day summary")
        #expect(item?.time == day(2026, 3, 4, 22))
    }

    @Test func daySummaryIsLeftOutWhenOffOrAlreadyShown() {
        let off = EngineHarness(at: day(2026, 3, 4, 10)) {
            only(&$0)
            $0.prefs.general.daySummaryOn = false
        }
        #expect(!off.engine.todayScreen.comingUp.contains { $0.kind == .daySummary })
        let shown = EngineHarness(at: day(2026, 3, 4, 10)) {
            only(&$0)
            $0.live.lastDaySummary = DayKey(day(2026, 3, 4), calendar: .current)
        }
        #expect(!shown.engine.todayScreen.comingUp.contains { $0.kind == .daySummary })
    }

    @Test func trackerAskComesUpAsStillOnItOrWhatNow() {
        let h = EngineHarness.tracker(at: wed(10))
        #expect(h.engine.todayScreen.comingUp.first { $0.kind == .trackerAsk }?.title != "Still on it?")
        h.start("Code review", minutes: 30)
        #expect(h.engine.todayScreen.comingUp.first { $0.kind == .trackerAsk }?.title == "Still on it?")
        #expect(h.engine.todayScreen.comingUp.first { $0.kind == .trackerAsk }?.detail == "Code review")
    }

    @Test func timesAreWholeMinutes() {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) {
            only(&$0, .water)
            $0.live.lastWaterDone = day(2026, 3, 4, 9, 30)
        }
        h.clock.now = h.clock.now.addingTimeInterval(17)
        h.engine.tick()
        for item in h.engine.todayScreen.comingUp {
            #expect(item.time.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 60) == 0)
        }
    }
}
