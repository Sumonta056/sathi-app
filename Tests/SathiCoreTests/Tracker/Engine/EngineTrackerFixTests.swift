import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker review fixes")
struct EngineTrackerFixTests {
    @Test func noIdleAwayDuringASessionAndTheSessionEndResetsTheLastInput() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.reading.sessionMinutes = 45 }
        h.start("Spec")
        h.clock.advance(minutes: 10)
        h.engine.startSession(.reading)
        h.presence.idleSeconds = 40 * 60
        h.advance(minutes: 35)
        #expect(h.presence.idleReads == 0)
        #expect(h.running?.kind == .buddy)
        #expect(h.store.live.tracker.awaySince == nil)
        h.engine.stopSession(.reading)
        h.engine.tick()
        #expect(h.store.live.tracker.lastInput == wed(10, 45))
        #expect(h.engine.trackerPromptState(.whatNow)?.resume?.text == "Spec")
        #expect(h.saved.map(\.kind) == [.work, .buddy])
    }

    @Test func aLockDuringABreakKeepsTheBreakUntilItEnds() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 30)
        h.clock.advance(minutes: 10)
        h.engine.pause(hours: 50.0 / 60)
        h.clock.advance(minutes: 5)
        h.engine.presenceChanged(.locked)
        h.clock.advance(minutes: 30)
        h.engine.presenceChanged(.unlocked)
        #expect(h.store.live.tracker.awaySince == wed(10, 10))
        #expect(!h.saved.contains { $0.kind == .away })
        h.advance(minutes: 15)
        let away = h.saved.filter { $0.kind == .away }
        #expect(away.map(\.awayPlace) == [.breakTime])
        #expect(away.map(\.start) == [wed(10, 10)])
        #expect(away.map(\.end) == [wed(11)])
        #expect(h.promptKind == .welcomeBack)
    }

    @Test func awakeAtMidnightAnUnansweredActivityEndsAtItsConfirmedTime() {
        let h = EngineHarness.tracker(at: wed(17)) { $0.prefs.tracker.endOfDayOn = false }
        h.start(minutes: 30)
        h.clock.advance(minutes: 7 * 60 - 1)
        h.engine.tick()
        h.advance(minutes: 1)
        #expect(h.running == nil)
        #expect(h.saved.first?.end == wed(17, 30))
    }

    private func doneHarness() -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.reading.sessionMinutes = 45 }
        h.start("Spec", minutes: 15)
        h.advance(minutes: 15)
        h.engine.stillOnIt(minutes: 5)
        h.advance(minutes: 12)
        h.engine.doneActivity()
        h.clock.advance(minutes: 13)
        return h
    }

    @Test func aSessionAfterDoneEndsTheDoneActivityAndOffersNoContinue() {
        let h = doneHarness()
        h.engine.startSession(.reading)
        #expect(h.saved.first?.end == wed(10, 27))
        h.clock.advance(minutes: 5)
        h.engine.stopSession(.reading)
        h.engine.tick()
        #expect(h.engine.trackerPromptState(.whatNow)?.resume == nil)
    }

    @Test func aBlockAfterDoneEndsTheDoneActivityAtTheDoneTime() {
        let h = doneHarness()
        h.startBlock("Plan", .minutes(30))
        #expect(h.saved.first?.end == wed(10, 27))
    }

    @Test func turningTheTrackerOffAfterDoneEndsAtTheDoneTime() {
        let h = doneHarness()
        h.engine.data.prefs.tracker.isOn = false
        #expect(h.saved.first?.end == wed(10, 27))
    }

    @Test func escOrTheCenterPanelOverADoneWhatNowEndTheActivity() {
        let esc = doneHarness()
        esc.engine.closeTrackerPrompt()
        #expect(esc.running == nil)
        #expect(esc.saved.first?.end == wed(10, 27))
        let center = doneHarness()
        center.engine.openTrackerPanel()
        #expect(center.running == nil)
        #expect(center.saved.first?.end == wed(10, 27))
    }

    @Test func turningTheTrackerOffEndsAtTheConfirmedTime() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 15)
        h.clock.advance(minutes: 40)
        h.engine.data.prefs.tracker.isOn = false
        #expect(h.saved.first?.end == wed(10, 15))
    }

    private func idleAwayHarness() -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.skipTrackerPrompt()
        h.presence.idleSeconds = 30 * 60
        h.advance(minutes: 30)
        h.clock.advance(minutes: 10)
        h.presence.idleSeconds = 0
        return h
    }

    @Test func startingAnActivityDuringAnIdleAwayEndsTheAwayWithNoWelcomeBack() {
        let h = idleAwayHarness()
        #expect(h.store.live.tracker.awaySince == wed(10))
        h.start("Back", minutes: 15)
        #expect(h.store.live.tracker.awaySince == nil)
        #expect(h.saved.map(\.kind) == [.away])
        #expect(h.saved.first?.end == wed(10, 40))
        h.advance(minutes: 15)
        #expect(h.promptKind == .stillOnIt)
        #expect(!h.trackerShows.contains(.welcomeBack))
    }

    @Test func openingTheCenterPanelDuringAnIdleAwayEndsTheAway() {
        let h = idleAwayHarness()
        h.engine.openTrackerPanel()
        #expect(h.store.live.tracker.awaySince == nil)
        #expect(h.promptKind == .center)
        h.advance(minutes: 1)
        #expect(h.promptKind == .center)
    }

    @Test func aTimeBlockAcrossMidnightIsSplitAtMidnight() {
        let h = EngineHarness.tracker(at: wed(23, 30)) { $0.prefs.tracker.endOfDayOn = false }
        h.startBlock("Plan", .minutes(90))
        h.clock.advance(minutes: 60)
        h.engine.endBlock()
        let blocks = h.saved.filter { $0.kind == .timeBlock }
        #expect(blocks.map(\.start) == [wed(23, 30), day(2026, 3, 5)])
        #expect(blocks.map(\.end) == [day(2026, 3, 5), day(2026, 3, 5, 0, 30)])
    }

    @Test(arguments: [day(2026, 3, 7, 10), wed(10)])
    func stillOnItDoesNotAskOnANonTrackerDayOrADayOff(_ start: Date) {
        let h = EngineHarness.tracker(at: start) { $0.prefs.tracker.daysOff = [DayKey(wed(10), calendar: .current)] }
        h.start(minutes: 15)
        h.advance(minutes: 20)
        #expect(h.promptKind == nil)
    }

    @Test func aRestoredPlainWhatNowOutsideHoursIsDropped() {
        let h = EngineHarness.tracker(at: wed(17, 55))
        #expect(h.promptKind == .whatNow)
        let again = EngineHarness.restartedTracker(from: h, at: wed(19))
        again.engine.start()
        #expect(again.promptKind == nil)
    }
}
