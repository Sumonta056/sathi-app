import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker calendar review fixes")
struct EngineTrackerEventFixTests {
    private func awayItems(_ h: EngineHarness) -> [[Date]] {
        h.saved.filter { $0.kind == .away }.map { [$0.start, $0.end] }
    }

    @Test func anAskFirstPromptLostToALockIsNotAskedAfterTheEventEnd() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.askEveryMinutes = 60 }
        h.useEvents([meeting(from: wed(10, 30), to: wed(11))], mode: .askFirst)
        h.start("Spec", minutes: 60)
        h.advance(minutes: 30)
        #expect(h.promptKind == .eventAsk)
        h.clock.advance(minutes: 1)
        h.engine.presenceChanged(.locked)
        h.advance(minutes: 44)
        h.engine.presenceChanged(.unlocked)
        #expect(h.promptKind == .welcomeBack)
        h.engine.closeTrackerPrompt()
        h.engine.tick()
        #expect(h.promptKind != .eventAsk)
        #expect(h.eventItems.isEmpty)
    }

    @Test func anAnsweredAskIsNotAskedAgainAfterALock() {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([meeting(from: wed(10, 30), to: wed(11))], mode: .askFirst)
        h.advance(minutes: 30)
        h.engine.answerEventAsk(false)
        h.engine.presenceChanged(.locked)
        h.advance(minutes: 10)
        h.engine.presenceChanged(.unlocked)
        h.engine.closeTrackerPrompt()
        h.engine.tick()
        #expect(h.promptKind != .eventAsk)
    }

    @Test func iWasHereAfterAnIdleMeetingKeepsTheEventOnce() {
        let h = EngineHarness.tracker(at: wed(9, 50))
        h.useEvents([meeting(from: wed(10), to: wed(10, 30))])
        h.advance(minutes: 10)
        #expect(h.running?.sourceEventID == "m1")
        h.presence.idleSeconds = 32 * 60
        h.advance(minutes: 30)
        #expect(h.tracker.awaySince == wed(9, 58))
        h.presence.idleSeconds = 0
        h.advance(minutes: 5)
        #expect(h.promptKind == .welcomeBack)
        h.engine.iWasHere()
        let standups = h.saved.filter { $0.sourceEventID == "m1" }.count + (h.running?.sourceEventID == "m1" ? 1 : 0)
        #expect(standups == 1)
    }

    @Test func anEventStartingInTheSecondOfTheReturnIsLogged() {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([meeting(from: wed(10, 50), to: wed(11, 20))])
        h.clock.advance(minutes: 20)
        h.engine.presenceChanged(.locked)
        h.advance(minutes: 30)
        h.engine.presenceChanged(.unlocked)
        h.engine.tick()
        #expect(h.running?.sourceEventID == "m1")
        #expect(h.running?.start == wed(10, 50))
    }

    @Test func aBreakEndingWhileLockedStoresTheEventToItsEndWithNoRunningEvent() {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([meeting(from: wed(10, 20), to: wed(11))])
        h.clock.advance(minutes: 10)
        h.engine.pause(hours: 0.5)
        h.clock.advance(minutes: 5)
        h.engine.presenceChanged(.locked)
        h.advance(minutes: 25)
        #expect(h.tracker.awaySince == wed(10, 40))
        #expect(h.running == nil)
        #expect(h.eventItems.map { [$0.start, $0.end] } == [[wed(10, 20), wed(11)]])
        h.advance(minutes: 50)
        h.engine.presenceChanged(.unlocked)
        #expect(h.running == nil)
        #expect(h.eventItems.count == 1)
        #expect(awayItems(h) == [[wed(10, 10), wed(10, 20)], [wed(11), wed(11, 30)]])
    }

    @Test func unsortedEventsStillGiveTheNextStartAsADeadline() {
        let h = EngineHarness.tracker(at: wed(10))
        h.calendarWriter.eventsValue = [meeting("late", from: wed(13), to: wed(14)), meeting("soon", from: wed(10, 12), to: wed(10, 40))]
        h.engine.data.prefs.tracker.readCalendarIDs = ["work"]
        h.engine.data.prefs.tracker.readsEvents = true
        h.engine.tick()
        #expect(h.engine.nextTickDelay() <= 12 * 60)
    }
}
