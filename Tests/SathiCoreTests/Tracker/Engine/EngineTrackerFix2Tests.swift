import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker review fixes 2")
struct EngineTrackerFix2Tests {
    @Test func aBreakThatEndsWhileLockedKeepsTheAwayUntilTheUnlock() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 30)
        h.clock.advance(minutes: 10)
        h.engine.pause(hours: 50.0 / 60)
        h.clock.advance(minutes: 5)
        h.engine.presenceChanged(.locked)
        h.advance(minutes: 50)
        #expect(h.promptKind == nil)
        #expect(h.store.live.tracker.awaySince == wed(11, 5))
        h.clock.advance(minutes: 10)
        h.engine.presenceChanged(.unlocked)
        let away = h.saved.filter { $0.kind == .away }
        #expect(away.map(\.awayPlace) == [.breakTime, nil])
        #expect(away.map(\.start) == [wed(10, 10), wed(11, 5)])
        #expect(away.map(\.end) == [wed(11, 5), wed(11, 15)])
        #expect(h.promptKind == .welcomeBack)
    }

    @Test func iWasHereNeverBringsBackAnActivityMarkedDone() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Spec", minutes: nil)
        h.advance(minutes: 15)
        h.engine.stillOnIt(minutes: 15)
        h.clock.advance(minutes: 5)
        h.engine.doneActivity()
        h.presence.idleSeconds = 30 * 60
        h.advance(minutes: 10)
        #expect(h.store.live.tracker.awaySince != nil)
        h.presence.idleSeconds = 0
        h.advance(minutes: 1)
        #expect(h.promptKind == .welcomeBack)
        h.engine.iWasHere()
        #expect(h.running == nil)
    }
}
