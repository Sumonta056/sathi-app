import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker calendar overlaps and dedupe")
struct EngineTrackerEventOverlapTests {
    @Test func whenTwoEventsOverlapTheFirstStaysAndANoteOffersSwitch() {
        let first = meeting("a", "Planning", from: wed(10, 30), to: wed(11, 30))
        let second = meeting("b", "Interview", from: wed(10, 45), to: wed(11, 15))
        let h = EngineHarness.tracker(at: wed(10, 20))
        h.useEvents([first, second])
        h.advance(minutes: 10)
        h.advance(minutes: 15)
        #expect(h.running?.text == "Planning")
        #expect(h.notes.last == .alsoNow(second))
        h.engine.switchToOverlappingEvent()
        #expect(h.running?.text == "Interview")
        #expect(h.running?.start == wed(10, 45))
        #expect(h.running?.sourceEventID == "b")
        #expect(h.eventItems.map(\.text) == ["Planning"])
        #expect(h.eventItems.first?.end == wed(10, 45))
        #expect(h.engine.trackerNoteState() == nil)
    }

    @Test func notAttendingTheSecondEventKeepsTheFirst() {
        let first = meeting("a", "Planning", from: wed(10, 30), to: wed(11, 30))
        let second = meeting("b", "Interview", from: wed(10, 45), to: wed(11, 15))
        let h = EngineHarness.tracker(at: wed(10, 20))
        h.useEvents([first, second])
        h.advance(minutes: 10)
        h.advance(minutes: 15)
        h.engine.notAttendingEvent("b")
        #expect(h.running?.text == "Planning")
        #expect(h.promptKind == nil)
        #expect(h.engine.trackerNoteState() == nil)
    }

    @Test func noEventIsLoggedTwoTimes() {
        let h = EngineHarness.tracker(at: wed(10, 20))
        h.useEvents([meeting(from: wed(10, 30), to: wed(10, 45))])
        h.advance(minutes: 10)
        for _ in 0 ..< 5 {
            h.advance(minutes: 1)
        }
        h.engine.startActivity(h.work("Review"))
        h.advance(minutes: 1)
        #expect(h.eventItems.count == 1)
        #expect(h.running?.text == "Review")
    }

    @Test func aRestartDuringALoggedEventDoesNotLogItAgain() {
        let h = EngineHarness.tracker(at: wed(10, 20))
        h.useEvents([meeting(from: wed(10, 30), to: wed(11))])
        h.advance(minutes: 10)
        let r = EngineHarness.restartedTracker(from: h, at: wed(10, 35))
        r.calendarWriter.eventsValue = h.calendarWriter.eventsValue
        r.engine.data.prefs.tracker.readsEvents = false
        r.engine.data.prefs.tracker.readsEvents = true
        r.engine.tick()
        r.advance(minutes: 1)
        #expect(r.running?.sourceEventID == "m1")
        #expect(r.running?.start == wed(10, 30))
        #expect(r.notes.isEmpty)
        r.engine.openTrackerPanel()
        #expect(r.engine.trackerPromptState(.center)?.runningEvent == nil)
    }

    @Test func aRecurringEventWithTheSameIDIsLoggedAtEachStart() {
        let h = EngineHarness.tracker(at: wed(10, 20))
        h.useEvents([
            meeting("r", "Check-in", from: wed(10, 30), to: wed(10, 45)),
            meeting("r", "Check-in", from: wed(14), to: wed(14, 15))
        ])
        h.advance(minutes: 10)
        h.advance(minutes: 15)
        h.engine.startActivity(h.work("Spec"))
        h.clock.advance(minutes: 60 * 3 + 15)
        h.engine.stillOnIt(minutes: 60)
        h.advance(minutes: 0)
        #expect(h.running?.text == "Check-in")
        #expect(h.running?.start == wed(14))
        #expect(h.eventItems.count == 1)
    }

    @Test func aRunningEventThatIsNotLoggedIsTheFirstChipInAAndB() {
        let e = meeting(from: wed(10, 30), to: wed(11))
        let h = EngineHarness.tracker(at: wed(10, 40))
        h.calendarWriter.eventsValue = [e]
        h.engine.data.prefs.tracker.readCalendarIDs = ["work"]
        h.engine.data.prefs.tracker.readsEvents = true
        h.engine.tick()
        #expect(h.running == nil)
        #expect(h.engine.trackerPromptState(.whatNow)?.runningEvent == e)
        h.engine.openTrackerPanel()
        #expect(h.engine.trackerPromptState(.center)?.runningEvent == e)
    }

    @Test func aTimeBlockOrABuddySessionSkipsTheEvent() {
        let h = EngineHarness.tracker(at: wed(10, 20))
        h.useEvents([meeting(from: wed(10, 30), to: wed(11))])
        h.clock.advance(minutes: 9)
        h.engine.startSession(.reading)
        h.advance(minutes: 1)
        #expect(h.running?.kind == .buddy)
        #expect(h.notes.isEmpty)
    }
}
