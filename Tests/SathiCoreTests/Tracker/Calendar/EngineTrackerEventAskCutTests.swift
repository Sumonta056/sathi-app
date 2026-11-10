import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker ask-first Yes after the event end")
struct EngineTrackerEventAskCutTests {
    private let standup = meeting(from: wed(10), to: wed(11))

    private func spans(_ h: EngineHarness) -> [String] {
        h.saved.map { "\($0.text) \(hm($0.start))-\(hm($0.end))" }
    }

    private func hm(_ d: Date) -> String {
        let c = Calendar.current.dateComponents([.hour, .minute], from: d)
        return String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
    }

    @Test func aYesAfterTheEventEndKeepsWorkStartedAfterTheEndRunning() {
        let h = EngineHarness.tracker(at: wed(9, 55))
        h.useEvents([standup], mode: .askFirst)
        h.advance(minutes: 5)
        #expect(h.promptKind == .eventAsk)
        h.clock.advance(minutes: 80)
        h.start("Coding", minutes: 60)
        h.advance(minutes: 20)
        h.answerAskWhenShown()
        #expect(h.running?.text == "Coding")
        #expect(h.running?.start == wed(11, 20))
        #expect(spans(h) == ["Standup 10:00-11:00"])
        #expect(h.eventItems.first?.kind == .event)
    }

    @Test func aYesAfterTheEventEndKeepsThePartOfStoredWorkAfterTheEnd() {
        let h = EngineHarness.tracker(at: wed(9))
        h.useEvents([standup], mode: .askFirst)
        h.start("Spec", minutes: 120)
        h.advance(minutes: 60)
        #expect(h.promptKind == .eventAsk)
        h.clock.advance(minutes: 50)
        h.start("Review", minutes: 90)
        h.clock.advance(minutes: 70)
        h.start("Mail", minutes: 30)
        h.advance(minutes: 10)
        h.answerAskWhenShown()
        #expect(spans(h) == ["Spec 09:00-10:00", "Standup 10:00-11:00", "Review 11:00-12:00"])
        #expect(h.running?.text == "Mail")
        #expect(h.running?.start == wed(12))
    }

    @Test func aYesAfterTheEventEndCutsTheRunningActivityAroundTheEvent() {
        let h = EngineHarness.tracker(at: wed(9))
        h.useEvents([standup], mode: .askFirst)
        h.start("Spec", minutes: 180)
        h.advance(minutes: 60)
        #expect(h.promptKind == .eventAsk)
        h.advance(minutes: 100)
        h.answerAskWhenShown()
        #expect(spans(h) == ["Spec 09:00-10:00", "Standup 10:00-11:00"])
        #expect(h.running?.text == "Spec")
        #expect(h.running?.start == wed(11))
        #expect(h.running?.kind == .work)
    }
}

private extension EngineHarness {
    func answerAskWhenShown() {
        if engine.trackerPrompt?.kind != .eventAsk { engine.closeTrackerPrompt() }
        engine.tick()
        engine.answerEventAsk(true)
    }
}
