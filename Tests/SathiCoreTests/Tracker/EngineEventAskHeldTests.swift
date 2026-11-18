import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine event ask holds other pop-ups")
struct EngineEventAskHeldTests {
    private let standup = meeting(from: wed(10, 30), to: wed(11))

    @Test func aWelcomeBackIsReplacedByTheEventAskAndComesBackAfterTheAnswer() {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([standup], mode: .askFirst)
        h.clock.advance(minutes: 10)
        h.engine.presenceChanged(.locked)
        h.advance(minutes: 15)
        h.engine.presenceChanged(.unlocked)
        h.engine.tick()
        #expect(h.promptKind == .welcomeBack)
        h.advance(minutes: 5)
        #expect(h.promptKind == .eventAsk)
        #expect(h.trackerShows.last == .eventAsk)
        h.engine.answerEventAsk(true)
        h.engine.tick()
        #expect(h.running?.sourceEventID == "m1")
        #expect(h.promptKind == .welcomeBack)
        #expect(h.trackerShows.last == .welcomeBack)
    }

    @Test func aSwitchWhatNowIsReplacedByTheEventAskAndComesBackAfter() {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([standup], mode: .askFirst)
        h.start("Spec", minutes: 60)
        h.advance(minutes: 20)
        h.engine.doneActivity()
        #expect(h.engine.trackerPrompt?.switchFrom != nil)
        h.advance(minutes: 10)
        #expect(h.promptKind == .eventAsk)
        h.engine.answerEventAsk(false)
        h.engine.tick()
        #expect(h.promptKind == .whatNow)
        #expect(h.engine.trackerPrompt?.switchFrom != nil)
        #expect(h.trackerShows.last == .whatNow)
    }

    @Test func aTodoDuePromptIsReplacedByTheEventAskAndItsTodosComeBackAfter() async {
        let todo = makeTodo("a", "Write report", due: timedDue(10, 20))
        let h = await EngineHarness.todoTracker(todos: [todo]) { $0.prefs.tracker.askEveryMinutes = 90 }
        h.useEvents([standup], mode: .askFirst)
        h.advance(minutes: 20)
        #expect(h.promptKind == .todoDue)
        h.advance(minutes: 10)
        #expect(h.promptKind == .eventAsk)
        h.engine.answerEventAsk(true)
        h.engine.tick()
        #expect(h.promptKind == .todoDue)
        #expect(h.engine.trackerPrompt?.todoIDs == ["a"])
        #expect(h.engine.trackerPromptState(.todoDue)?.todos.map(\.id) == ["a"])
    }

    @Test func aLaterEventReplacesTheEarlierAskAndTheEarlierAsksNextWhileStillOn() {
        let first = meeting("a", "Planning", from: wed(10, 30), to: wed(11, 30))
        let second = meeting("b", "Interview", from: wed(10, 35), to: wed(11))
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([first, second], mode: .askFirst)
        h.advance(minutes: 30)
        #expect(h.engine.trackerPrompt?.eventID == "a")
        h.advance(minutes: 5)
        #expect(h.engine.trackerPrompt?.eventID == "b")
        h.engine.answerEventAsk(false)
        h.engine.tick()
        #expect(h.promptKind == .eventAsk)
        #expect(h.engine.trackerPrompt?.eventID == "a")
    }

    @Test func anEarlierEventThatIsOverIsNotAskedAfterTheLaterAsk() {
        let first = meeting("a", "Planning", from: wed(10, 30), to: wed(10, 40))
        let second = meeting("b", "Interview", from: wed(10, 35), to: wed(11))
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([first, second], mode: .askFirst)
        h.advance(minutes: 30)
        h.advance(minutes: 5)
        #expect(h.engine.trackerPrompt?.eventID == "b")
        h.advance(minutes: 10)
        h.engine.answerEventAsk(false)
        h.engine.tick()
        #expect(h.promptKind != .eventAsk)
    }
}
