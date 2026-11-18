import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine event ask logged while away")
struct EngineEventAskAwayLogTests {
    private let standup = meeting(from: wed(10, 30), to: wed(11))

    private func askThenIdle() -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.askEveryMinutes = 60 }
        h.useEvents([standup], mode: .askFirst)
        h.start("Spec", minutes: 60)
        h.advance(minutes: 30)
        return h
    }

    private func comeBackAt1116(_ h: EngineHarness) {
        h.presence.idleSeconds = 44 * 60
        h.advance(minutes: 45)
        h.presence.idleSeconds = 0
        h.advance(minutes: 1)
    }

    @Test func anOpenAskIsLoggedByItselfWhenTheEventEndsDuringAnIdleAway() {
        let h = askThenIdle()
        #expect(h.promptKind == .eventAsk)
        comeBackAt1116(h)
        #expect(h.tracker.awaySince == nil)
        #expect(h.saved.first { $0.kind == .away }?.start == wed(11))
        #expect(h.promptKind == .welcomeBack)
        #expect(h.eventItems.map { [$0.start, $0.end] } == [[wed(10, 30), wed(11)]])
        #expect(h.saved.filter { $0.kind == .work }.allSatisfy { $0.end <= wed(10, 30) })
        #expect(h.engine.trackerPromptState(.welcomeBack)?.loggedWhileAway.map(\.sourceEventID) == ["m1"])
        h.engine.closeTrackerPrompt()
        h.engine.tick()
        #expect(h.promptKind != .eventAsk)
    }

    @Test func aDismissedEventIsNeverLoggedWhileAway() {
        let h = askThenIdle()
        h.engine.answerEventAsk(false)
        comeBackAt1116(h)
        #expect(h.eventItems.isEmpty)
    }

    @Test func backWhileTheEventIsOnAsksAgainAndLogsNothingByItself() {
        let h = askThenIdle()
        h.clock.advance(minutes: 1)
        h.engine.presenceChanged(.locked)
        h.advance(minutes: 9)
        h.engine.presenceChanged(.unlocked)
        h.engine.tick()
        #expect(h.promptKind == .eventAsk)
        #expect(h.eventItems.isEmpty)
    }
}
