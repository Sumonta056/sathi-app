import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker restore and platform")
struct EngineTrackerRestoreTests {
    @Test func theRunningActivityAndTheOpenPromptSurviveARestart() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Spec", minutes: 15)
        h.advance(minutes: 16)
        #expect(h.promptKind == .stillOnIt)
        let again = EngineHarness.restartedTracker(from: h, at: wed(10, 20))
        again.engine.start()
        #expect(again.running == h.running)
        #expect(again.promptKind == .stillOnIt)
        #expect(again.trackerShows == [.stillOnIt])
        #expect(again.engine.trackerPromptState(.stillOnIt)?.shownAt == wed(10, 16))
    }

    @Test func aRestartOnALaterDayEndsTheOldActivityAtItsConfirmedTime() {
        let h = EngineHarness.tracker(at: wed(16)) { $0.prefs.tracker.askEveryMinutes = 30 }
        h.start("Spec", minutes: 30)
        let again = EngineHarness.restartedTracker(from: h, at: day(2026, 3, 5, 8))
        again.engine.start()
        #expect(again.running == nil)
        #expect(again.saved.first?.end == wed(16, 30))
        #expect(again.promptKind == nil)
    }

    @Test func startListensForPresenceAndRegistersTheShortcut() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.start()
        #expect(h.presence.starts == 1)
        #expect(h.hotkeys.registered == [KeyShortcut.trackerDefault])
        h.hotkeys.press()
        #expect(h.promptKind == .center)
        h.presence.send(.locked)
        #expect(h.store.live.tracker.awaySince == wed(10))
        h.engine.stop()
        #expect(h.presence.stops == 1)
        #expect(h.hotkeys.unregisters == 1)
    }

    @Test func aTrackerThatIsOffNeverListens() {
        let h = EngineHarness.quiet(at: wed(10))
        h.engine.start()
        #expect(h.presence.starts == 0)
        #expect(h.hotkeys.registered.isEmpty)
    }

    @Test func turningTheTrackerOffEndsTheActivityAndStopsListening() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.start()
        h.start("Spec", minutes: 30)
        h.clock.advance(minutes: 10)
        h.engine.data.prefs.tracker.isOn = false
        #expect(h.running == nil)
        #expect(h.saved.first?.end == wed(10, 10))
        #expect(h.promptKind == nil)
        #expect(h.presence.stops == 1)
        #expect(h.hotkeys.unregisters == 1)
    }

    @Test func aNewShortcutIsRegisteredAgain() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.start()
        let next = KeyShortcut(keyCode: 40, modifiers: [.control, .option], keyName: "K")
        h.engine.data.prefs.tracker.shortcut = next
        #expect(h.hotkeys.registered == [KeyShortcut.trackerDefault, next])
        #expect(h.hotkeys.unregisters == 1)
    }

    @Test func theNextAskIsATickDeadline() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 15)
        h.clock.advance(minutes: 14.75)
        h.engine.tick()
        #expect(h.engine.nextTickDelay() <= 15)
    }

    @Test func theStartOfTrackerHoursIsATickDeadline() {
        let h = EngineHarness.tracker(at: wed(8, 59, s: 30))
        #expect(h.engine.nextTickDelay() <= 30)
    }
}
