import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine event ask review fixes")
struct EngineEventAskReviewTests {
    private let standup = meeting(from: wed(10, 30), to: wed(11))

    private func idleWelcomeBack(_ mode: EventMode = .askFirst) -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(9, 50))
        h.useEvents([standup], mode: mode)
        h.start("Spec", minutes: 120)
        h.presence.idleSeconds = 30 * 60
        h.advance(minutes: 30)
        h.presence.idleSeconds = 0
        h.advance(minutes: 5)
        return h
    }

    @Test func iWasHereAfterAYesKeepsTheLoggedEventAndTheAwayRows() {
        let h = idleWelcomeBack()
        #expect(h.promptKind == .welcomeBack)
        let away = h.saved.filter { $0.kind == .away }
        #expect(!away.isEmpty)
        h.advance(minutes: 5)
        #expect(h.promptKind == .eventAsk)
        h.engine.answerEventAsk(true)
        h.engine.tick()
        #expect(h.promptKind == .welcomeBack)
        #expect(h.engine.trackerPromptState(.welcomeBack)?.offersIWasHere == false)
        h.engine.iWasHere()
        #expect(h.running?.sourceEventID == "m1")
        #expect(h.running?.start == wed(10, 30))
        #expect(h.saved.filter { $0.kind == .away } == away)
    }

    @Test func aYesDuringAPauseKeepsTheBreakAwayRowBeforeTheEvent() {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([standup], mode: .askFirst)
        h.start("Spec", minutes: 60)
        h.clock.advance(minutes: 20)
        h.engine.pause(hours: 1)
        h.advance(minutes: 10)
        #expect(h.promptKind == .eventAsk)
        h.engine.answerEventAsk(true)
        h.clock.advance(minutes: 10)
        h.engine.resume()
        h.engine.tick()
        let away = h.saved.filter { $0.kind == .away }.map { [$0.start, $0.end] }
        #expect(away == [[wed(10, 20), wed(10, 30)]])
        #expect(h.running?.sourceEventID == "m1")
    }

    @Test func aDoneTimeHeldUnderTheEventAskEndsTheActivityAtDone() {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([standup], mode: .askFirst)
        h.start("Spec", minutes: 60)
        h.advance(minutes: 20)
        h.engine.doneActivity()
        h.advance(minutes: 10)
        #expect(h.promptKind == .eventAsk)
        h.engine.answerEventAsk(true)
        #expect(h.saved.first { $0.text == "Spec" }?.end == wed(10, 20))
    }

    @Test func aDoneTimeHeldUnderTheEventAskIsKeptByALock() {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([standup], mode: .askFirst)
        h.start("Spec", minutes: 60)
        h.advance(minutes: 20)
        h.engine.doneActivity()
        h.advance(minutes: 10)
        h.clock.advance(minutes: 5)
        h.engine.presenceChanged(.locked)
        #expect(h.saved.first { $0.text == "Spec" }?.end == wed(10, 20))
    }

    @Test func threeCloseEventsAreAllAskedInStartOrder() {
        let a = meeting("a", "Planning", from: wed(10, 30), to: wed(11, 30))
        let b = meeting("b", "Interview", from: wed(10, 35), to: wed(11, 30))
        let c = meeting("c", "Sync", from: wed(10, 40), to: wed(11, 30))
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([a, b, c], mode: .askFirst)
        h.advance(minutes: 30)
        h.advance(minutes: 5)
        h.advance(minutes: 5)
        #expect(h.engine.trackerPrompt?.eventID == "c")
        var asked: [String] = []
        for _ in 0 ..< 3 {
            h.engine.answerEventAsk(false)
            h.engine.tick()
            if let id = h.engine.trackerPrompt?.eventID { asked.append(id) }
        }
        #expect(asked == ["a", "b"])
        #expect(h.promptKind != .eventAsk)
    }

    @Test func logAndTellWithAnotherPopUpOpenAsksAndLogsNothing() {
        let h = idleWelcomeBack(.logAndTell)
        #expect(h.promptKind == .welcomeBack)
        h.advance(minutes: 5)
        #expect(h.promptKind == .eventAsk)
        #expect(h.running?.sourceEventID == nil)
        #expect(h.notes.isEmpty)
    }

    @Test func notAttendingBringsBackTheHeldPopUp() {
        let h = idleWelcomeBack()
        h.advance(minutes: 5)
        #expect(h.promptKind == .eventAsk)
        h.engine.notAttendingEvent("m1")
        h.engine.tick()
        #expect(h.promptKind == .welcomeBack)
        #expect(h.trackerShows.last == .welcomeBack)
    }
}
