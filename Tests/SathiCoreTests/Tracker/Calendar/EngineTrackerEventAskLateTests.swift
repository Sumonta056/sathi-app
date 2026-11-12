import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker ask-first late answers")
struct EngineTrackerEventAskLateTests {
    private let standup = meeting(from: wed(10), to: wed(11))

    @Test func aLateYesLogsFromTheEventStartAndRemovesTheActivityStartedAfterIt() {
        let h = EngineHarness.tracker(at: wed(9))
        h.useEvents([standup], mode: .askFirst)
        h.start("Spec", minutes: 120)
        h.advance(minutes: 60)
        #expect(h.promptKind == .eventAsk)
        h.advance(minutes: 10)
        h.start("Review", minutes: 30)
        h.advance(minutes: 20)
        h.answerAskWhenShown()
        #expect(h.running?.text == "Standup")
        #expect(h.running?.start == wed(10))
        #expect(h.saved.map(\.text) == ["Spec"])
        #expect(h.saved.first?.end == wed(10))
    }

    @Test func aLateYesRemovesStoredWorkThatStartedInsideTheEvent() {
        let h = EngineHarness.tracker(at: wed(9))
        h.useEvents([standup], mode: .askFirst)
        h.start("Spec", minutes: 120)
        h.advance(minutes: 70)
        h.start("Review", minutes: 30)
        h.advance(minutes: 10)
        h.start("Mail", minutes: 30)
        h.advance(minutes: 10)
        h.answerAskWhenShown()
        #expect(h.running?.start == wed(10))
        #expect(h.saved.map(\.text) == ["Spec"])
    }

    @Test func alsoNowIsHeldDuringQuietTime() {
        let first = meeting("a", "Planning", from: wed(10, 30), to: wed(11, 30))
        let second = meeting("b", "Interview", from: wed(10, 45), to: wed(11, 15))
        let h = EngineHarness.tracker(at: wed(10, 20))
        h.useEvents([first, second])
        h.advance(minutes: 10)
        h.clock.advance(minutes: 1)
        var draft = h.work("Planning", minutes: 60, quiet: true)
        draft.sourceEventID = "a"
        h.engine.startActivity(draft, switchAt: wed(10, 30))
        h.advance(minutes: 14)
        #expect(h.engine.trackerQuietUntil != nil)
        #expect(!h.notes.contains(.alsoNow(second)))
        #expect(h.running?.text == "Planning")
    }
}

private extension EngineHarness {
    func answerAskWhenShown() {
        if engine.trackerPrompt?.kind != .eventAsk { engine.closeTrackerPrompt() }
        engine.tick()
        engine.answerEventAsk(true)
    }
}
