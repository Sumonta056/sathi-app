import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine time block check-in and restart")
struct EngineTimeBlockCheckInTests {
    private let t0 = day(2026, 3, 4, 10)

    @Test func openBlockAsksAfterTwoHours() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .open)
        h.advance(minutes: 119)
        #expect(!h.engine.blockCheckInShowing)
        #expect(!h.presenter.calls.contains(.showBlockCheckIn))
        h.advance(minutes: 1)
        #expect(h.engine.blockCheckInShowing)
        #expect(h.presenter.calls.contains(.showBlockCheckIn))
        #expect(h.sound.played.contains(.ping))
        #expect(h.engine.timeBlock != nil)
        #expect(h.calendarWriter.saved.isEmpty)
    }

    @Test func checkInIsSilentWhenSoundIsOff() {
        let h = EngineHarness.quiet { $0.prefs.timeBlock.playsSound = false }
        h.startBlock("Plan", .open)
        h.advance(minutes: 120)
        #expect(h.presenter.calls.contains(.showBlockCheckIn))
        #expect(!h.sound.played.contains(.ping))
    }

    @Test func keepGoingAsksAgainTwoHoursLater() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .open)
        h.advance(minutes: 120)
        h.engine.keepGoingBlock()
        #expect(!h.engine.blockCheckInShowing)
        #expect(h.presenter.calls.contains(.closeBlockCheckIn))
        #expect(h.engine.timeBlock?.nextCheckIn == t0.addingTimeInterval(2 * Timing.blockCheckIn))
        h.advance(minutes: 119)
        #expect(!h.engine.blockCheckInShowing)
        h.advance(minutes: 1)
        #expect(h.engine.blockCheckInShowing)
    }

    @Test func plannedBlockNeverAsks() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(120))
        h.advance(minutes: 119)
        #expect(!h.presenter.calls.contains(.showBlockCheckIn))
    }

    @Test func aBlockContinuesAfterARestart() {
        let h = EngineHarness.quiet()
        let id = h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 10)
        let again = EngineHarness.restarted(from: h, at: t0.addingTimeInterval(10 * Timing.minute))
        #expect(again.engine.timeBlock?.id == id)
        #expect(again.engine.blockStatusText == "20m")
        again.advance(minutes: 20)
        #expect(again.calendarWriter.saved.map(\.end) == [t0.addingTimeInterval(30 * Timing.minute)])
    }

    @Test func anOverduePlannedEndSavesWithThePlannedEnd() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        let again = EngineHarness.restarted(from: h, at: t0.addingTimeInterval(3 * Timing.hour))
        #expect(again.engine.timeBlock == nil)
        #expect(again.calendarWriter.saved == [
            CalendarEventDraft(calendarID: "work", title: "Plan", start: t0, end: t0.addingTimeInterval(30 * Timing.minute))
        ])
    }

    @Test func anOverdueCheckInShowsAtTheFirstTick() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .open)
        let again = EngineHarness.restarted(from: h, at: t0.addingTimeInterval(3 * Timing.hour))
        #expect(again.engine.blockCheckInShowing)
    }

    @Test func anOverdueCapSavesAtTwelveHours() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .open)
        let again = EngineHarness.restarted(from: h, at: t0.addingTimeInterval(20 * Timing.hour))
        #expect(again.calendarWriter.saved.map(\.end) == [t0.addingTimeInterval(Timing.blockCap)])
    }
}
