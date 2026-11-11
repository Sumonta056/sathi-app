import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker gate")
struct EngineTrackerGateTests {
    @Test(arguments: [wed(8, 59), wed(18), wed(22), day(2026, 3, 7, 10)])
    func noPromptOutsideTrackerHoursOrOnANonTrackerDay(_ start: Date) {
        let h = EngineHarness.tracker(at: start)
        h.advance(minutes: 0.5)
        #expect(h.trackerShows.isEmpty)
    }

    @Test func noPromptOnATrackerDayOff() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.daysOff = [DayKey(wed(10), calendar: .current)] }
        h.advance(minutes: 60)
        #expect(h.trackerShows.isEmpty)
    }

    @Test func noPromptDuringABreakAndTheBreakEndsTheActivity() {
        let h = EngineHarness.tracker(at: wed(8))
        h.start(minutes: 15)
        h.advance(minutes: 70)
        h.engine.skipTrackerPrompt()
        h.engine.pause(hours: 1)
        h.advance(minutes: 50)
        #expect(h.running == nil)
        #expect(h.promptKind == nil)
        #expect(h.trackerShows == [.stillOnIt])
    }

    @Test func noPromptWhileATimeBlockRunsAndTheBlockEndsTheActivity() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 15)
        h.advance(minutes: 5)
        h.startBlock("Plan", .minutes(60))
        #expect(h.running == nil)
        #expect(h.saved.map(\.end) == [wed(10, 5)])
        h.advance(minutes: 30)
        #expect(h.promptKind == nil)
        #expect(h.trackerShows == [.whatNow])
    }

    @Test func aSavedTimeBlockAddsAReadOnlyActivity() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.skipTrackerPrompt()
        h.startBlock("Plan", .minutes(60))
        h.advance(minutes: 20)
        h.engine.endBlock()
        let item = h.saved.last
        #expect(item?.kind == .timeBlock)
        #expect(item?.text == "Plan")
        #expect(item?.category == nil)
        #expect(item?.start == wed(10, 0))
        #expect(item?.end == wed(10, 20))
    }

    @Test func aFullScreenLockHoldsTrackerPromptsUntilItEnds() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.water.enabled = true }
        h.engine.skipTrackerPrompt()
        h.showReminder(.water)
        h.engine.snooze(.water)
        h.advance(minutes: 5)
        h.engine.snooze(.water)
        h.advance(minutes: 5)
        #expect(h.engine.phase(.water) == .lock)
        h.advance(minutes: 10)
        #expect(h.trackerShows == [.whatNow])
        #expect(h.promptKind == nil)
        h.engine.lockConfirmed(.water)
        h.engine.tick()
        #expect(h.trackerShows == [.whatNow, .whatNow])
    }

    @Test func aLockAndStillOnItAtTheSameMomentShowTheLockFirst() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.water.enabled = true }
        h.start(minutes: 15)
        h.showReminder(.water)
        h.engine.snooze(.water)
        h.advance(minutes: 5)
        h.engine.snooze(.water)
        h.advance(minutes: 10)
        #expect(h.engine.phase(.water) == .lock)
        #expect(h.promptKind == nil)
        h.engine.lockConfirmed(.water)
        h.engine.tick()
        #expect(h.promptKind == .stillOnIt)
    }

    @Test func quietTimeHoldsTrackerAndBuddyPopupsUntilTheExpectedEnd() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.water.enabled = true }
        h.start(minutes: 30, quiet: true)
        #expect(h.engine.trackerQuietUntil == wed(10, 30))
        h.advance(minutes: 10)
        h.showReminder(.water)
        h.advance(minutes: 10)
        #expect(!h.presenter.calls.contains(.showBubble(.water, .nudge)))
        h.advance(minutes: 10)
        #expect(h.presenter.calls.contains(.showBubble(.water, .nudge)))
        #expect(h.promptKind == .stillOnIt)
    }

    @Test func quickRemindersStillShowDuringQuietTime() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 30, quiet: true)
        _ = h.engine.addQuick(text: "Call", when: .inMinutes(5))
        h.advance(minutes: 5)
        #expect(h.presenter.calls.contains { if case .showQuick = $0 { true } else { false } })
    }

    @Test func quietIsOffForAnOpenActivity() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: nil, quiet: true)
        #expect(h.engine.trackerQuietUntil == nil)
    }

    @Test func theShortcutEndsQuietTimeAndOpensTheCenterPanel() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 30, quiet: true)
        h.engine.trackerShortcutPressed()
        #expect(h.engine.trackerQuietUntil == nil)
        #expect(h.promptKind == .center)
        #expect(h.trackerShows.last == .center)
    }

    @Test func theMenuEndsQuietTime() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 30, quiet: true)
        h.engine.openTrackerPanel()
        #expect(h.engine.trackerQuietUntil == nil)
        #expect(h.store.live.tracker.running?.quietUntil == nil)
    }

    @Test func doneEndsQuietTime() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 30, quiet: true)
        h.engine.doneActivity()
        #expect(h.engine.trackerQuietUntil == nil)
        #expect(h.promptKind == .whatNow)
    }

    @Test func escInTheCenterPanelClosesItAndAsksAgainLater() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.openTrackerPanel()
        #expect(h.presenter.trackerCalls.last == .showPrompt(.center))
        h.engine.closeTrackerPrompt()
        #expect(h.promptKind == nil)
        h.advance(minutes: 15)
        #expect(h.promptKind == .whatNow)
    }
}
