import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker wave 3 review fixes")
struct EngineTrackerWaveThreeFixTests {
    private func awaySpans(_ h: EngineHarness) -> [[Date]] {
        h.saved.filter { $0.kind == .away }.map { [$0.start, $0.end] }
    }

    private func thu(_ hour: Int, _ minute: Int = 0) -> Date { day(2026, 3, 5, hour, minute) }

    @Test func idleAwayDuringAPausedBreathKeepsTheBuddyActivityAndTheEndStillOffersContinue() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Spec", minutes: 60)
        h.clock.advance(minutes: 10)
        h.engine.startSession(.meditation)
        h.clock.advance(minutes: 2)
        h.engine.pauseSession(.meditation)
        h.presence.idleSeconds = 35 * 60
        h.advance(minutes: 35)
        #expect(h.tracker.awaySince != nil)
        #expect(h.running?.kind == .buddy)
        h.clock.advance(minutes: 3)
        h.presence.idleSeconds = 0
        h.engine.resumeSession(.meditation)
        #expect(h.tracker.awaySince == nil)
        #expect(h.running?.kind == .buddy)
        #expect(!h.trackerShows.contains(.welcomeBack))
        h.clock.advance(minutes: 2)
        h.engine.finishSession(.meditation)
        #expect(h.promptKind == .whatNow)
        #expect(h.engine.trackerPromptState(.whatNow)?.resume?.text == "Spec")
        let buddy = h.saved.filter { $0.kind == .buddy }.map { [$0.start, $0.end] }
        #expect(buddy == [[wed(10, 10), wed(10, 52)]])
        #expect(awaySpans(h).isEmpty)
    }

    @Test func aMidnightDuringAwayNeverLetsAwayOverlapTheKeptEvent() {
        let h = EngineHarness.tracker(at: wed(16, 55))
        h.useEvents([meeting(from: wed(17), to: wed(17, 45))])
        h.start("Spec", minutes: 60)
        h.advance(minutes: 5)
        #expect(h.running?.sourceEventID == "m1")
        h.clock.advance(minutes: 10)
        h.engine.presenceChanged(.locked)
        h.clock.advance(minutes: 7 * 60)
        h.engine.tick()
        #expect(h.running == nil)
        h.clock.advance(minutes: 9 * 60 + 20)
        h.engine.data.prefs.tracker.readsEvents = false
        h.engine.presenceChanged(.unlocked)
        #expect(h.eventItems.map { [$0.start, $0.end] } == [[wed(17), wed(17, 45)]])
        #expect(awaySpans(h) == [[wed(17, 45), wed(18)], [thu(9), thu(9, 30)]])
    }

    @Test func anIdleStartBeforeAKeptEventNeverOverlapsTheActivityThatEndedAtTheEventStart() {
        let h = EngineHarness.tracker(at: wed(9, 40))
        h.useEvents([meeting(from: wed(10), to: wed(11))])
        h.start("Spec", minutes: 60)
        h.advance(minutes: 10)
        h.presence.idleSeconds = 10 * 60
        h.advance(minutes: 10)
        #expect(h.running?.sourceEventID == "m1")
        h.presence.idleSeconds = 30 * 60
        h.advance(minutes: 20)
        #expect(h.tracker.awaySince != nil)
        h.presence.idleSeconds = 0
        h.advance(minutes: 60)
        #expect(h.saved.first { $0.text == "Spec" }?.end == wed(10))
        #expect(awaySpans(h) == [[wed(11), wed(11, 20)]])
    }

    @Test func aMidnightWithTheEndOfDayOffDoesNotShowAnOldDayWhenTurnedOnLater() {
        let h = EngineHarness.tracker(at: wed(17, 30)) { $0.prefs.tracker.endOfDayOn = false }
        h.start(minutes: 60)
        h.engine.stillOnIt(minutes: 7 * 60)
        h.advance(minutes: 30)
        h.clock.advance(minutes: 6 * 60 - 1)
        h.engine.tick()
        h.advance(minutes: 1)
        #expect(h.running == nil)
        h.clock.advance(minutes: 10 * 60)
        h.engine.data.prefs.tracker.endOfDayOn = true
        h.engine.tick()
        h.engine.skipTrackerPrompt()
        h.engine.tick()
        #expect(!h.presenter.trackerCalls.contains(.showEndOfDay))
        h.advance(minutes: 8 * 60)
        h.engine.skipTrackerPrompt()
        h.engine.tick()
        #expect(h.presenter.trackerCalls.filter { $0 == .showEndOfDay }.count == 1)
        #expect(h.store.live.tracker.lastEndOfDay == DayKey(thu(18), calendar: .current))
    }

    @Test func anEditThatEndsInTheFutureIsRefused() {
        let spec = Activity(text: "Spec", start: wed(10), end: wed(11))
        let h = EngineHarness.tracker(at: wed(12), activities: [spec])
        let edit = ActivityEdit(text: "Spec", category: nil, start: wed(10), end: wed(13))
        #expect(h.engine.editActivity(spec.id, edit) == .inFuture)
        #expect(h.saved.first?.end == wed(11))
        let now = ActivityEdit(text: "Spec", category: nil, start: wed(10), end: wed(12))
        #expect(h.engine.editActivity(spec.id, now) == .saved(spec.id))
    }
}
