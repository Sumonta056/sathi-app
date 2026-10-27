import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine snooze limit change")
struct EngineSnoozeLimitChangeTests {
    @Test func raisingTheLimitGivesAnOpenBubbleItsIgnoreTimerBack() {
        let h = limitHarness(1)
        snoozeAndReturn(h)
        #expect(h.engine.ignoreDeadline(.water) == .distantFuture)
        h.engine.data.prefs.general.snoozeLimit = 3
        #expect(h.engine.ignoreDeadline(.water) == h.clock.now.addingTimeInterval(5 * 60))
        h.advance(minutes: 5)
        #expect(h.engine.state(.water).snoozes == 2)
        #expect(snoozeEvents(h) == 2)
    }

    @Test func noLimitGivesAnOpenBubbleItsIgnoreTimerBack() {
        let h = limitHarness(1)
        snoozeAndReturn(h)
        h.engine.data.prefs.general.snoozeLimit = nil
        h.advance(minutes: 5)
        #expect(h.engine.state(.water).snoozes == 2)
    }

    @Test func loweringTheLimitStopsTheIgnoreTimerOfAnOpenBubble() {
        let h = limitHarness(3)
        snoozeAndReturn(h)
        h.engine.data.prefs.general.snoozeLimit = 1
        #expect(h.engine.ignoreDeadline(.water) == .distantFuture)
        h.advance(minutes: 10)
        #expect(h.engine.phase(.water) == .bubble(.nudge))
        #expect(h.engine.state(.water).snoozes == 1)
        #expect(snoozeEvents(h) == 1)
    }

    @Test func aLimitChangeThatKeepsSnoozesLeavesTheTimerAlone() {
        let h = limitHarness(5)
        let deadline = h.engine.ignoreDeadline(.water)
        h.advance(minutes: 2)
        h.engine.data.prefs.general.snoozeLimit = 3
        #expect(h.engine.ignoreDeadline(.water) == deadline)
    }
}
