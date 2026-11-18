import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine event ask and I was here")
struct EngineEventAskIWasHereTests {
    private let standup = meeting(from: wed(10, 30), to: wed(11))

    @Test func iWasHereIsNotOfferedAfterAYesForAnEventThatStartedBeforeTheReturn() {
        let long = meeting(from: wed(10, 30), to: wed(11, 30))
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.askEveryMinutes = 60 }
        h.useEvents([long], mode: .askFirst)
        h.start("Spec", minutes: 60)
        h.advance(minutes: 30)
        h.advance(minutes: 2)
        h.presence.idleSeconds = 31 * 60
        h.advance(minutes: 31)
        h.presence.idleSeconds = 0
        h.advance(minutes: 1)
        h.advance(minutes: 1)
        #expect(h.promptKind == .eventAsk)
        h.engine.answerEventAsk(true)
        h.engine.tick()
        #expect(h.engine.trackerPromptState(.welcomeBack)?.offersIWasHere == false)
        let before = h.saved
        h.engine.iWasHere()
        #expect(h.running?.sourceEventID == "m1")
        #expect(h.saved == before)
    }

    @Test func iWasHereIsNotOfferedAfterAWaitedEventWasLogged() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.askEveryMinutes = 60 }
        h.useEvents([standup], mode: .askFirst)
        h.start("Spec", minutes: 60)
        h.advance(minutes: 30)
        h.presence.idleSeconds = 44 * 60
        h.advance(minutes: 45)
        h.presence.idleSeconds = 0
        h.advance(minutes: 1)
        #expect(h.engine.trackerPromptState(.welcomeBack)?.loggedWhileAway.map(\.text) == ["Standup"])
        #expect(h.engine.trackerPromptState(.welcomeBack)?.offersIWasHere == false)
        let before = h.saved
        h.engine.iWasHere()
        #expect(h.saved == before)
        #expect(h.running == nil)
    }

    @Test func anOpenAskPastTheEventEndIsLoggedWhenALockStartsLater() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.askEveryMinutes = 60 }
        h.useEvents([standup], mode: .askFirst)
        h.start("Spec", minutes: 90)
        h.advance(minutes: 30)
        h.advance(minutes: 35)
        #expect(h.promptKind == .eventAsk)
        h.engine.presenceChanged(.locked)
        h.advance(minutes: 10)
        h.engine.presenceChanged(.unlocked)
        #expect(h.eventItems.map { [$0.start, $0.end] } == [[wed(10, 30), wed(11)]])
    }

    @Test func anUnansweredAskDuringAPauseIsNotLoggedByItself() {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([standup], mode: .askFirst)
        h.start("Spec", minutes: 60)
        h.clock.advance(minutes: 20)
        h.engine.pause(hours: 1)
        h.advance(minutes: 10)
        #expect(h.promptKind == .eventAsk)
        h.advance(minutes: 35)
        #expect(h.promptKind == .eventAsk)
        #expect(h.eventItems.isEmpty)
    }

    @Test func anEventEndingBetweenTheLastInputAndTheReturnTickIsLogged() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.askEveryMinutes = 60 }
        h.useEvents([standup], mode: .askFirst)
        h.start("Spec", minutes: 60)
        h.advance(minutes: 30)
        h.presence.idleSeconds = 44 * 60
        h.advance(minutes: 45)
        #expect(h.tracker.awaySince == wed(10, 31))
        h.presence.idleSeconds = 17 * 60
        h.advance(minutes: 1)
        #expect(h.tracker.awaySince == nil)
        #expect(h.eventItems.map { [$0.start, $0.end] } == [[wed(10, 30), wed(11)]])
        #expect(h.promptKind != .eventAsk)
    }
}
