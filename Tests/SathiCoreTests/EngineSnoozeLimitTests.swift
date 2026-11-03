import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
func limitHarness(_ limit: Int?, _ strictness: Strictness = .friendly) -> EngineHarness {
    let h = EngineHarness {
        $0.prefs.general.snoozeLimit = limit
        $0.prefs.general.snoozeMinutes = 5
        $0.prefs.general.ignoreMinutes = 5
        $0.prefs.water.strictness = strictness
    }
    h.showReminder(.water)
    return h
}

@MainActor
func snoozeAndReturn(_ h: EngineHarness, _ id: HabitID = .water) {
    h.engine.snooze(id)
    h.advance(minutes: 5)
}

@MainActor
func snoozeEvents(_ h: EngineHarness, _ id: HabitID = .water) -> Int {
    h.history.appended.filter { $0.habit == id && $0.kind == .snooze }.count
}

@MainActor
@Suite("Engine snooze limit")
struct EngineSnoozeLimitTests {
    @Test func noLimitMeansNoCount() {
        let h = limitHarness(nil)
        #expect(h.engine.snoozesLeft(.water) == nil)
        #expect(h.engine.canSnooze(.water))
    }

    @Test func snoozesLeftCountsDownWithEachSnooze() {
        let h = limitHarness(3)
        #expect(h.engine.snoozesLeft(.water) == 3)
        snoozeAndReturn(h)
        #expect(h.engine.snoozesLeft(.water) == 2)
        snoozeAndReturn(h)
        #expect(h.engine.snoozesLeft(.water) == 1)
        #expect(h.engine.canSnooze(.water))
        snoozeAndReturn(h)
        #expect(h.engine.snoozesLeft(.water) == 0)
        #expect(!h.engine.canSnooze(.water))
    }

    @Test func snoozesLeftNeverGoesBelowZero() {
        let h = limitHarness(nil)
        snoozeAndReturn(h)
        snoozeAndReturn(h)
        snoozeAndReturn(h)
        h.engine.data.prefs.general.snoozeLimit = 1
        #expect(h.engine.snoozesLeft(.water) == 0)
        #expect(!h.engine.canSnooze(.water))
    }

    @Test func snoozeAtTheLimitDoesNothing() {
        let h = limitHarness(1)
        snoozeAndReturn(h)
        #expect(h.engine.phase(.water) == .bubble(.nudge))
        let before = h.engine.state(.water).snoozedUntil
        h.engine.snooze(.water)
        #expect(h.engine.phase(.water) == .bubble(.nudge))
        #expect(h.engine.state(.water).snoozes == 1)
        #expect(snoozeEvents(h) == 1)
        #expect(h.engine.state(.water).snoozedUntil == before)
    }

    @Test func aBubbleWithNoSnoozeLeftHasNoIgnoreTimer() {
        let h = limitHarness(1)
        snoozeAndReturn(h)
        #expect(h.engine.ignoreDeadline(.water) == .distantFuture)
        h.advance(minutes: 6)
        h.advance(minutes: 30)
        #expect(h.engine.phase(.water) == .bubble(.nudge))
        #expect(h.engine.state(.water).snoozes == 1)
        #expect(snoozeEvents(h) == 1)
    }

    @Test func aBubbleWithSnoozesLeftKeepsItsIgnoreTimer() {
        let h = limitHarness(2)
        #expect(h.engine.ignoreDeadline(.water) == h.clock.now.addingTimeInterval(5 * Timing.minute))
        h.advance(minutes: 5)
        #expect(h.engine.activities[.water] == nil)
        #expect(h.engine.state(.water).snoozes == 1)
    }

    @Test func withNoLimitSnoozesNeverRunOut() {
        let h = limitHarness(nil)
        for n in 1 ... 16 {
            snoozeAndReturn(h)
            #expect(h.engine.state(.water).snoozes == n)
        }
        #expect(h.engine.canSnooze(.water))
        h.advance(minutes: 5)
        #expect(h.engine.activities[.water] == nil)
        #expect(h.engine.state(.water).snoozes == 17)
    }

    @Test func loggingWaterGivesTheNextReminderTheFullLimit() {
        let h = limitHarness(2)
        snoozeAndReturn(h)
        snoozeAndReturn(h)
        #expect(!h.engine.canSnooze(.water))
        h.engine.logWater(1)
        h.engine.endCelebrate()
        h.showReminder(.water)
        #expect(h.engine.snoozesLeft(.water) == 2)
        #expect(h.engine.canSnooze(.water))
    }

    @Test func emergencySkipClosesAnOpenBubbleAndResetsTheCount() {
        let h = limitHarness(1)
        snoozeAndReturn(h)
        h.engine.emergencySkip(.water)
        #expect(h.engine.activities[.water] == nil)
        #expect(h.presenter.calls.contains(.closeBubble(.water)))
        #expect(h.history.appended.last == .skip(.water, at: h.clock.now))
        #expect(h.engine.snoozesLeft(.water) == 1)
    }

    @Test func theLimitCountsEachHabitOnItsOwn() {
        let h = limitHarness(1)
        snoozeAndReturn(h)
        h.showReminder(.reading)
        #expect(!h.engine.canSnooze(.water))
        #expect(h.engine.canSnooze(.reading))
        #expect(h.engine.snoozesLeft(.reading) == 1)
    }
}
