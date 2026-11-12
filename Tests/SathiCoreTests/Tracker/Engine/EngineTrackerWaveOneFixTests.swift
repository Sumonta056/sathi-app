import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker wave 1 fixes")
struct EngineTrackerWaveOneFixTests {
    @Test func aPausedBreathingSessionDoesNotTurnTheIdleCheckOff() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.meditation.sessionMinutes = 10 }
        h.start("Spec")
        h.engine.startMeditation()
        h.advance(minutes: 2)
        h.engine.pauseSession(.meditation)
        h.presence.idleSeconds = 30 * 60
        h.advance(minutes: 30)
        #expect(h.store.live.tracker.awaySince == wed(10, 2))
        #expect(h.engine.session(.meditation)?.isPaused == true)
    }

    @Test func aRunningSessionStillHoldsTheIdleCheck() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.meditation.sessionMinutes = 45 }
        h.engine.startMeditation()
        h.presence.idleSeconds = 40 * 60
        h.advance(minutes: 35)
        #expect(h.store.live.tracker.awaySince == nil)
    }

    @Test func dKeepsItsAwayDetailsAfterARestart() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Spec", minutes: 60)
        h.clock.advance(minutes: 20)
        h.engine.presenceChanged(.locked)
        h.clock.advance(minutes: 30)
        h.engine.presenceChanged(.unlocked)
        #expect(h.promptKind == .welcomeBack)
        let again = EngineHarness.restartedTracker(from: h, at: wed(10, 52))
        again.engine.start()
        let away = again.engine.trackerPromptState(.welcomeBack)?.away
        #expect(away?.start == wed(10, 20))
        #expect(away?.end == wed(10, 50))
        again.engine.setAwayPlace(.lunch)
        #expect(again.saved.filter { $0.kind == .away }.map(\.awayPlace) == [.lunch])
    }

    @Test func iWasHereWorksAfterARestart() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Spec", minutes: 60)
        h.clock.advance(minutes: 10)
        h.engine.tick()
        h.presence.idleSeconds = 30 * 60
        h.advance(minutes: 30)
        h.clock.advance(minutes: 5)
        h.presence.idleSeconds = 0
        h.engine.tick()
        #expect(h.promptKind == .welcomeBack)
        let again = EngineHarness.restartedTracker(from: h, at: wed(10, 46))
        again.engine.start()
        again.engine.iWasHere()
        #expect(again.saved.filter { $0.kind == .away }.isEmpty)
        #expect(again.running?.text == "Spec")
        #expect(again.running?.start == wed(10))
    }

    @Test func theEndOfDayShowsForADayWhoseActivityEndedAtMidnight() {
        let h = EngineHarness.tracker(at: wed(17, 30))
        h.start(minutes: 60)
        h.engine.stillOnIt(minutes: 7 * 60)
        h.advance(minutes: 30)
        #expect(h.presenter.trackerCalls.filter { $0 == .showEndOfDay }.isEmpty)
        h.clock.advance(minutes: 6 * 60 - 1)
        h.engine.tick()
        h.advance(minutes: 1)
        #expect(h.running == nil)
        #expect(h.presenter.trackerCalls.filter { $0 == .showEndOfDay }.count == 1)
        #expect(h.store.live.tracker.lastEndOfDay == DayKey(wed(12), calendar: .current))
        #expect(h.engine.trackerEndOfDayState()?.day.day == DayKey(wed(12), calendar: .current))
        h.engine.closeTrackerEndOfDay()
        h.advance(minutes: 60)
        #expect(h.presenter.trackerCalls.filter { $0 == .showEndOfDay }.count == 1)
        h.advance(minutes: 17 * 60)
        #expect(h.presenter.trackerCalls.filter { $0 == .showEndOfDay }.count == 2)
    }

    @Test func turningTheTrackerOffWhileRunningEndsAtTheConfirmedTimeNotNow() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.askEveryMinutes = 30 }
        h.start(minutes: 30)
        h.clock.advance(minutes: 50)
        h.engine.data.prefs.tracker.isOn = false
        #expect(h.saved.first?.end == wed(10, 30))
        let early = EngineHarness.tracker(at: wed(10))
        early.start(minutes: 30)
        early.clock.advance(minutes: 10)
        early.engine.data.prefs.tracker.isOn = false
        #expect(early.saved.first?.end == wed(10, 10))
    }
}
