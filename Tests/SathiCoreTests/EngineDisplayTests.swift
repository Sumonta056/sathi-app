import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine display")
struct EngineDisplayTests {
    @Test func statusShowsTimeToNextReminder() {
        let h = EngineHarness()
        #expect(h.engine.status.text == "2h 0m")
        #expect(!h.engine.status.isBook)
    }

    @Test func statusTextPerPhase() {
        let h = EngineHarness()
        h.showReminder(.water)
        #expect(h.engine.status.text == "Drink!")
        h.engine.snooze()
        h.engine.startReading()
        h.engine.tick()
        #expect(h.engine.status.text == "15:00")
        #expect(h.engine.status.isBook)
    }

    @Test func pillDescribesEachState() {
        let h = EngineHarness()
        #expect(h.engine.pill(.water) == "in 2h 0m")
        #expect(h.engine.pill(.reading) == "at " + day(2026, 3, 4, 22).formatted(date: .omitted, time: .shortened))
        h.showReminder(.water)
        #expect(h.engine.pill(.water) == "Due now")
        h.engine.snooze()
        h.engine.tick()
        #expect(h.engine.pill(.water) == "Snoozed · 5m")
        h.engine.data.prefs.reading.enabled = false
        #expect(h.engine.pill(.reading) == "Off")
    }

    @Test func moodFollowsTheWaterLevel() {
        let h = EngineHarness()
        #expect(h.engine.mood(.water) == .happy)
        h.advance(minutes: 100)
        #expect(h.engine.mood(.water) == .thirsty)
    }

    @Test func waterLevelDrainsOverTheInterval() {
        let h = EngineHarness()
        #expect(h.engine.waterLevel == 1)
        h.advance(minutes: 60)
        #expect(abs(h.engine.waterLevel - 0.5) < 0.001)
    }

    @Test func snoozeLabelWarnsBeforeTheLock() {
        let h = EngineHarness()
        h.showReminder(.water)
        #expect(h.engine.snoozeLabel(.water) == "Snooze 5 min")
        h.engine.snooze()
        h.advance(minutes: 5)
        #expect(h.engine.snoozeLabel(.water) == "Last snooze")
        #expect(h.engine.warnText(.water).contains("pauses your screen"))
    }

    @Test func goalTextShowsProgress() {
        let h = EngineHarness()
        h.engine.logWater(1.5)
        #expect(h.engine.goalText(.water) == GoalText(done: "1½", rest: "of 8 glasses"))
        #expect(h.engine.goalText(.reading) == GoalText(done: "0", rest: "of 15 min"))
        #expect(h.engine.progress(.water) == 1.5 / 8)
    }

    @Test func idleTickWaitsForTheNextMinuteChange() {
        let h = EngineHarness()
        h.clock.advance(minutes: 0.5)
        h.engine.tick()
        let delay = h.engine.nextTickDelay()
        #expect(delay > 29 && delay < 31)
    }

    @Test func focusPicksTheSoonestHabit() {
        let h = EngineHarness(at: day(2026, 3, 4, 21, 0))
        #expect(h.engine.focus == .reading)
    }
}
