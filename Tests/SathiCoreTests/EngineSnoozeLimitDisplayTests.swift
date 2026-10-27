import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine snooze limit display")
struct EngineSnoozeLimitDisplayTests {
    @Test func closeButtonHidesWhenNoSnoozeIsLeft() {
        let h = limitHarness(1)
        #expect(h.engine.showsClose(.water, level: .nudge))
        snoozeAndReturn(h)
        #expect(h.engine.data.prefs.showsCloseButton(.water))
        #expect(!h.engine.showsClose(.water, level: .nudge))
    }

    @Test func oneSnoozeLeftSaysLastSnooze() {
        let h = limitHarness(2)
        #expect(h.engine.snoozeLabel(.water) == "Snooze 5 min")
        snoozeAndReturn(h)
        #expect(h.engine.snoozeLabel(.water) == "Last snooze")
    }

    @Test func aLimitOfOneSaysLastSnoozeAtOnce() {
        let h = limitHarness(1)
        #expect(h.engine.snoozeLabel(.water) == "Last snooze")
    }

    @Test func noLimitKeepsTheNormalLabel() {
        let h = limitHarness(nil)
        snoozeAndReturn(h)
        #expect(h.engine.snoozeLabel(.water) == "Snooze 5 min")
    }

    @Test func lockNextStillSaysLastSnooze() {
        let h = limitHarness(5, .strict)
        snoozeAndReturn(h)
        #expect(h.engine.snoozeLabel(.water) == "Last snooze")
    }

    @Test(arguments: HabitID.allCases)
    func warnTextAtTheLimitNamesTheBuddy(_ id: HabitID) {
        let h = EngineHarness(at: day(2026, 3, 4, 15)) {
            $0.prefs.general.snoozeLimit = 1
            $0.prefs.meditation.enabled = true
            $0.prefs.gym.enabled = true
            $0.prefs.water.strictness = .friendly
            $0.prefs.reading.strictness = .friendly
            $0.prefs.meditation.strictness = .friendly
            $0.prefs.gym.strictness = .friendly
        }
        h.showReminder(id)
        snoozeAndReturn(h, id)
        #expect(!h.engine.canSnooze(id))
        #expect(h.engine.warnText(id) == "No snoozes left. \(id.buddy) stays until you're done.")
    }

    @Test func warnTextWithSnoozesLeftIsUnchanged() {
        let h = limitHarness(3, .persistent)
        snoozeAndReturn(h)
        #expect(h.engine.warnText(.water) == "No close button. Fota stays on top until you're done.")
    }

    @Test(arguments: [1, 3])
    func eyebrowCountsTheUsedSnoozes(_ limit: Int) {
        let h = limitHarness(limit)
        for _ in 0 ..< limit {
            snoozeAndReturn(h)
        }
        #expect(h.engine.noSnoozeEyebrow(.water) == "NO SNOOZES LEFT · \(limit) OF \(limit) USED")
    }

    @Test func strictWithALimitOfOneNeverLocks() {
        let h = limitHarness(1, .strict)
        snoozeAndReturn(h)
        #expect(h.engine.phase(.water) == .bubble(.persist))
        h.engine.snooze(.water)
        h.advance(minutes: 5)
        h.advance(minutes: 30)
        #expect(h.engine.phase(.water) == .bubble(.persist))
        #expect(!h.presenter.calls.contains(.showLock(.water)))
        #expect(h.engine.state(.water).snoozes == 1)
    }

    @Test func strictWithALimitOfThreeStillLocksAfterTwoSnoozes() {
        let h = limitHarness(3, .strict)
        snoozeAndReturn(h)
        #expect(h.engine.phase(.water) == .bubble(.persist))
        snoozeAndReturn(h)
        #expect(h.engine.phase(.water) == .lock)
        #expect(h.presenter.calls.last == .showLock(.water))
    }

    @Test func strictWithALimitOfTwoLocksAfterTwoSnoozes() {
        let h = limitHarness(2, .strict)
        snoozeAndReturn(h)
        snoozeAndReturn(h)
        #expect(h.engine.phase(.water) == .lock)
    }
}
