import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker away")
struct EngineTrackerAwayTests {
    private func lockedHarness(lockAt minutes: Double, unlockAt back: Double) -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Write spec", minutes: 30)
        h.clock.advance(minutes: minutes)
        h.engine.presenceChanged(.locked)
        h.clock.advance(minutes: back - minutes)
        h.engine.presenceChanged(.unlocked)
        return h
    }

    @Test func awayAfterTheConfirmedTimeEndsTheActivityAtTheConfirmedTime() {
        let h = lockedHarness(lockAt: 40, unlockAt: 60)
        #expect(h.saved.map(\.kind) == [.work, .away])
        #expect(h.saved[0].end == wed(10, 30))
        #expect(h.saved[1].start == wed(10, 40))
        #expect(h.saved[1].end == wed(11))
        #expect(h.saved[1].awayPlace == nil)
    }

    @Test func awayBeforeTheConfirmedTimeEndsTheActivityAtTheAwayStart() {
        let h = lockedHarness(lockAt: 20, unlockAt: 50)
        #expect(h.saved[0].end == wed(10, 20))
        #expect(h.running == nil)
    }

    @Test func returnInsideTrackerHoursShowsWelcomeBackWithoutIWasHereAfterALock() {
        let h = lockedHarness(lockAt: 20, unlockAt: 50)
        #expect(h.promptKind == .welcomeBack)
        let s = h.engine.trackerPromptState(.welcomeBack)
        #expect(s?.away?.start == wed(10, 20))
        #expect(s?.away?.fromIdle == false)
        #expect(s?.lastActivity?.text == "Write spec")
        h.engine.iWasHere()
        #expect(h.saved.count == 2)
        #expect(h.running == nil)
    }

    @Test func sleepAndWakeAreAwayToo() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 30)
        h.clock.advance(minutes: 10)
        h.engine.presenceChanged(.sleep)
        h.clock.advance(minutes: 10)
        h.engine.presenceChanged(.wake)
        #expect(h.saved.map(\.kind) == [.work, .away])
        #expect(h.promptKind == .welcomeBack)
    }

    @Test func wakeWhileTheScreenIsLockedIsStillAway() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.presenceChanged(.locked)
        h.engine.presenceChanged(.sleep)
        h.clock.advance(minutes: 10)
        h.engine.presenceChanged(.wake)
        #expect(h.promptKind == nil)
        h.engine.presenceChanged(.unlocked)
        #expect(h.promptKind == .welcomeBack)
    }

    @Test func returnAfterTrackerHoursSavesOnlyTheAwayInsideHoursAndShowsNoWelcomeBack() {
        let h = EngineHarness.tracker(at: wed(17, 50))
        h.engine.presenceChanged(.locked)
        h.clock.advance(minutes: 40)
        h.engine.presenceChanged(.unlocked)
        #expect(h.saved.map(\.start) == [wed(17, 50)])
        #expect(h.saved.map(\.end) == [wed(18)])
        #expect(h.promptKind != .welcomeBack)
    }

    @Test func idleAwayStartsAtTheLastInputAndIWasHerePutsTheActivityBack() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Deep work", minutes: nil)
        h.presence.idleSeconds = 10 * 60
        h.advance(minutes: 30)
        #expect(h.presence.idleReads == 1)
        #expect(h.promptKind == .stillOnIt)
        h.presence.idleSeconds = 30 * 60
        h.advance(minutes: 20)
        #expect(h.running == nil)
        #expect(h.saved.first?.end == wed(10, 15))
        h.presence.idleSeconds = 0
        h.advance(minutes: 10)
        #expect(h.promptKind == .welcomeBack)
        #expect(h.engine.trackerPromptState(.welcomeBack)?.away?.fromIdle == true)
        #expect(h.saved.last?.kind == .away)
        #expect(h.saved.last?.start == wed(10, 20))
        h.engine.iWasHere()
        #expect(h.saved.isEmpty)
        #expect(h.running?.text == "Deep work")
        #expect(h.running?.start == wed(10))
        #expect(h.promptKind == nil)
    }

    @Test func idleIsReadOnlyAtTheIdleDeadline() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.skipTrackerPrompt()
        for _ in 0 ..< 29 {
            h.advance(minutes: 1)
        }
        #expect(h.presence.idleReads == 0)
        h.advance(minutes: 1)
        #expect(h.presence.idleReads == 1)
    }

    @Test func backToLastActivityStartsItAgainFromNow() {
        let h = lockedHarness(lockAt: 20, unlockAt: 50)
        h.engine.backToLastActivity()
        #expect(h.running?.text == "Write spec")
        #expect(h.running?.start == wed(10, 50))
        #expect(h.promptKind == nil)
    }

    @Test func aPlaceChipNamesTheAwayItem() {
        let h = lockedHarness(lockAt: 20, unlockAt: 50)
        h.engine.setAwayPlace(.lunch)
        #expect(h.saved.last?.awayPlace == .lunch)
        #expect(h.saved.last?.text == Copywriter.trackerAwayText(.lunch))
        #expect(h.engine.trackerPromptState(.welcomeBack)?.away?.place == .lunch)
    }

    @Test func escInWelcomeBackKeepsTheAway() {
        let h = lockedHarness(lockAt: 20, unlockAt: 50)
        h.engine.closeTrackerPrompt()
        #expect(h.promptKind == nil)
        #expect(h.saved.last?.kind == .away)
    }

    @Test func takeABreakEndsTheActivityAndIsAwayBreakThenWelcomeBack() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 30)
        h.clock.advance(minutes: 10)
        h.engine.pause(hours: 0.5)
        #expect(h.running == nil)
        #expect(h.saved.first?.end == wed(10, 10))
        h.advance(minutes: 30)
        #expect(h.saved.last?.kind == .away)
        #expect(h.saved.last?.awayPlace == .breakTime)
        #expect(h.saved.last?.start == wed(10, 10))
        #expect(h.saved.last?.end == wed(10, 40))
        #expect(h.promptKind == .welcomeBack)
    }
}
