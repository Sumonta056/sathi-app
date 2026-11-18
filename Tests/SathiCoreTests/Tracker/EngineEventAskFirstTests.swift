import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine event ask comes first")
struct EngineEventAskFirstTests {
    private let standup = meeting(from: wed(10, 30), to: wed(11))

    private func harness(_ mode: EventMode = .askFirst) -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([standup], mode: mode)
        return h
    }

    @Test func aRunningTimeBlockStillGetsTheAskAndKeepsRunning() {
        let h = harness()
        h.clock.advance(minutes: 20)
        h.startBlock("Deep work", .minutes(60))
        h.advance(minutes: 10)
        #expect(h.promptKind == .eventAsk)
        #expect(h.trackerShows.last == .eventAsk)
        #expect(h.engine.timeBlock?.isRunning == true)
    }

    @Test func aPauseStillGetsTheAsk() {
        let h = harness()
        h.clock.advance(minutes: 20)
        h.engine.pause(hours: 1)
        h.advance(minutes: 10)
        #expect(h.promptKind == .eventAsk)
        #expect(h.trackerShows.last == .eventAsk)
    }

    @Test func aBuddySessionStillGetsTheAskAndKeepsRunning() {
        let h = harness()
        h.clock.advance(minutes: 20)
        h.engine.startSession(.reading)
        h.advance(minutes: 10)
        #expect(h.promptKind == .eventAsk)
        #expect(h.trackerShows.last == .eventAsk)
        #expect(h.engine.session(.reading) != nil)
    }

    @Test func logAndTellWithATimeBlockAsksAndLogsNothingByItself() {
        let h = harness(.logAndTell)
        h.clock.advance(minutes: 20)
        h.startBlock("Deep work", .minutes(60))
        h.advance(minutes: 10)
        #expect(h.promptKind == .eventAsk)
        #expect(h.running?.sourceEventID == nil)
        #expect(h.eventItems.isEmpty)
        #expect(h.notes.isEmpty)
    }

    @Test func anAskLostToAwayShowsOnReturnWhileTheEventIsOn() {
        let h = harness()
        h.advance(minutes: 30)
        #expect(h.promptKind == .eventAsk)
        h.clock.advance(minutes: 1)
        h.engine.presenceChanged(.locked)
        h.advance(minutes: 5)
        #expect(h.promptKind == nil)
        h.advance(minutes: 9)
        h.engine.presenceChanged(.unlocked)
        h.engine.tick()
        #expect(h.promptKind == .eventAsk)
        #expect(h.trackerShows.last == .eventAsk)
    }

    @Test func anAskLostToAwayIsNotShownWhenTheEventIsOver() {
        let h = harness()
        h.advance(minutes: 30)
        h.clock.advance(minutes: 1)
        h.engine.presenceChanged(.locked)
        h.advance(minutes: 44)
        h.engine.presenceChanged(.unlocked)
        h.engine.tick()
        h.engine.closeTrackerPrompt()
        h.engine.tick()
        h.advance(minutes: 1)
        #expect(h.promptKind != .eventAsk)
    }

    @Test func aWaitingEventThatIsDismissedIsNotAskedAgain() {
        let h = harness()
        h.advance(minutes: 30)
        h.clock.advance(minutes: 1)
        h.engine.presenceChanged(.locked)
        h.advance(minutes: 5)
        h.engine.notAttendingEvent("m1")
        h.advance(minutes: 4)
        h.engine.presenceChanged(.unlocked)
        h.engine.tick()
        #expect(h.promptKind != .eventAsk)
    }

    @Test func aWaitingEventThatIsLoggedIsNotAskedAgain() {
        let h = harness()
        h.advance(minutes: 30)
        h.clock.advance(minutes: 1)
        h.engine.presenceChanged(.locked)
        h.advance(minutes: 5)
        var draft = h.work("Standup", minutes: 20)
        draft.sourceEventID = "m1"
        h.engine.startActivity(draft)
        h.engine.tick()
        #expect(h.promptKind != .eventAsk)
        #expect(h.running?.sourceEventID == "m1")
    }

    @Test func withNothingInTheWayTheAskShowsAtTheStart() {
        let h = harness()
        h.start("Spec", minutes: 60)
        h.advance(minutes: 30)
        #expect(h.promptKind == .eventAsk)
        #expect(h.trackerShows.last == .eventAsk)
        #expect(h.running?.text == "Spec")
    }

    @Test func withNothingInTheWayLogAndTellLogsAndShowsTheNote() {
        let h = harness(.logAndTell)
        h.start("Spec", minutes: 60)
        h.advance(minutes: 30)
        #expect(h.running?.sourceEventID == "m1")
        #expect(h.notes == [.event(standup)])
        #expect(h.promptKind == nil)
    }
}
