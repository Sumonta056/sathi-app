import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine goal met")
struct EngineGoalMetTests {
    private func drinkEight(_ h: EngineHarness) {
        for _ in 0 ..< 8 {
            h.engine.logWater(1)
        }
        h.engine.endCelebrate()
    }

    private func waterShows(_ calls: ArraySlice<SpyPresenter.Call>) -> Bool {
        calls.contains {
            switch $0 {
            case .showBubble(.water, _), .showLock(.water), .showSession(.water), .showSnoozed(.water, _): return true
            default: return false
            }
        }
    }

    @Test func noWaterReminderForTheRestOfTheDayAfterTheGoal() {
        let h = EngineHarness()
        drinkEight(h)
        let mark = h.presenter.calls.count
        for _ in 0 ..< 27 {
            h.advance(minutes: 30)
        }
        #expect(!waterShows(h.presenter.calls[mark...]))
        #expect(h.engine.activities[.water] == nil)
    }

    @Test func waterNextDueIsTomorrowsStartAfterTheGoal() {
        let h = EngineHarness()
        drinkEight(h)
        #expect(h.engine.state(.water).nextDue == day(2026, 3, 5, 9, 30))
        #expect(h.engine.remaining(.water) == day(2026, 3, 5, 9, 30).timeIntervalSince(day(2026, 3, 4, 10)))
    }

    @Test func waterRemindsAgainTomorrowMorning() {
        let h = EngineHarness()
        drinkEight(h)
        h.advance(minutes: 23 * 60 + 29)
        let mark = h.presenter.calls.count
        h.advance(minutes: 1)
        #expect(waterShows(h.presenter.calls[mark...]))
    }

    @Test func sevenGlassesKeepTheIntervalToday() {
        let h = EngineHarness()
        for _ in 0 ..< 7 {
            h.engine.logWater(1)
        }
        h.engine.endCelebrate()
        #expect(h.engine.state(.water).nextDue == day(2026, 3, 4, 12))
    }

    @Test func raisingTheGoalBringsBackTodaysReminder() {
        let h = EngineHarness()
        drinkEight(h)
        h.engine.data.prefs.water.dailyGoalGlasses = 10
        #expect(h.engine.state(.water).nextDue == day(2026, 3, 4, 12))
        let mark = h.presenter.calls.count
        h.advance(minutes: 120)
        #expect(waterShows(h.presenter.calls[mark...]))
    }

    @Test func raisingTheGoalAfterTheDueTimeRemindsAtOnce() {
        let h = EngineHarness()
        drinkEight(h)
        h.advance(minutes: 300)
        let mark = h.presenter.calls.count
        h.engine.data.prefs.water.dailyGoalGlasses = 10
        h.advance(minutes: 1)
        #expect(waterShows(h.presenter.calls[mark...]))
    }

    @Test func goalMetAtLaunchWaitsUntilTomorrow() {
        let h = EngineHarness { $0.events = [.done(.water, 8, at: day(2026, 3, 4, 9, 45))] }
        #expect(h.engine.state(.water).nextDue == day(2026, 3, 5, 9, 30))
    }
}
