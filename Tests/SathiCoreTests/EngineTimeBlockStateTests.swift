import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine time block access, waiting, and status")
struct EngineTimeBlockStateTests {
    private let t0 = day(2026, 3, 4, 10)

    private func waiting() -> EngineHarness {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.calendarWriter.nextSaveResult = .calendarMissing
        h.advance(minutes: 30)
        return h
    }

    @Test func accessFollowsTheWriterAtTheNextTick() {
        let h = EngineHarness.quiet()
        h.calendarWriter.access = .denied
        h.advance(minutes: 1)
        #expect(h.engine.calendarAccess == .denied)
        h.calendarWriter.access = .allowed
        h.advance(minutes: 1)
        #expect(h.engine.calendarAccess == .allowed)
    }

    @Test func ticksInsideOneMinuteReadAccessOnce() {
        let h = EngineHarness.quiet()
        h.engine.tick()
        let before = h.calendarWriter.accessReads
        for _ in 0 ..< 5 {
            h.engine.tick()
        }
        #expect(h.calendarWriter.accessReads == before)
        h.advance(minutes: 1)
        #expect(h.calendarWriter.accessReads > before)
    }

    @Test func refreshingAccessOnDemandReadsTheWriter() {
        let h = EngineHarness.quiet()
        h.calendarWriter.access = .denied
        h.engine.refreshCalendarAccess()
        #expect(h.engine.calendarAccess == .denied)
    }

    @Test func openingTheStartPopupRefreshesAccess() {
        let h = EngineHarness.quiet()
        h.calendarWriter.access = .denied
        h.engine.openBlockStart()
        #expect(h.engine.calendarAccess == .denied)
        #expect(h.presenter.calls.contains(.showBlockStart))
    }

    @Test func startWhileABlockWaitsIsRefused() throws {
        let h = waiting()
        let result = h.engine.startBlock(title: "New", length: .minutes(15), calendarID: "home")
        #expect(result == .blockWaiting)
        #expect(h.presenter.calls.contains(.closeBlockStart))
        let block = try #require(h.engine.timeBlock)
        #expect(block.title == "Plan")
        #expect(block.waitingForCalendar)
    }

    @Test func startWhenTheOldSaveFailsIsRefused() throws {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(60))
        h.advance(minutes: 5)
        h.calendarWriter.nextSaveResult = .failed
        let result = h.engine.startBlock(title: "New", length: .minutes(15), calendarID: "home")
        #expect(result == .blockWaiting)
        #expect(h.presenter.calls.contains(.closeBlockStart))
        #expect(h.presenter.calls.contains(.showBlockCalendarGone))
        let block = try #require(h.engine.timeBlock)
        #expect(block.title == "Plan")
        #expect(block.endedAt == t0.addingTimeInterval(5 * Timing.minute))
        #expect(h.presenter.blockNotes.isEmpty)
    }

    @Test func launchShowsTheCalendarGonePopupAgain() {
        let h = waiting()
        let again = EngineHarness.restarted(from: h, at: t0.addingTimeInterval(Timing.hour))
        again.engine.start()
        again.engine.stop()
        #expect(again.presenter.calls.contains(.showBlockCalendarGone))
    }

    @Test func pausedWinsOverTheBlockText() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.engine.pause(hours: 1)
        h.advance(minutes: 5)
        #expect(h.engine.status.text == "Paused")
    }

    @Test func lockedWinsOverTheBlockText() {
        let h = EngineHarness {
            $0.prefs.general.snoozeMinutes = 5
            $0.prefs.general.ignoreMinutes = 5
            $0.prefs.water.strictness = .strict
        }
        h.startBlock("Plan", .minutes(120))
        h.showReminder(.water)
        snoozeAndReturn(h)
        snoozeAndReturn(h)
        #expect(h.engine.phase(.water) == .lock)
        #expect(h.engine.status.text == "Locked")
    }

    @Test func wholeHoursShowNoMinutes() {
        #expect(Copywriter.blockMinutes(120) == "2h")
        #expect(Copywriter.blockMinutes(125) == "2h 5m")
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .open)
        h.advance(minutes: 60)
        #expect(h.engine.blockStatusText == "1h")
    }
}
