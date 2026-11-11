import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine end of day waits for the prompt")
struct EngineEndOfDayWaitTests {
    private func endOfDays(_ h: EngineHarness) -> Int { h.presenter.trackerCalls.count { $0 == .showEndOfDay } }

    private func endOfHoursWithAPrompt() -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(17, 50))
        #expect(h.promptKind == .whatNow)
        h.advance(minutes: 10)
        return h
    }

    @Test func theEndOfHoursWithAPromptOpenShowsNoEndOfDay() {
        let h = endOfHoursWithAPrompt()
        #expect(h.promptKind == .whatNow)
        #expect(endOfDays(h) == 0)
        #expect(h.store.live.tracker.lastEndOfDay == nil)
        h.advance(minutes: 30)
        #expect(endOfDays(h) == 0)
    }

    @Test func theEndOfDayShowsAtTheNextTickAfterTheSkip() {
        let h = endOfHoursWithAPrompt()
        h.engine.skipTrackerPrompt()
        h.engine.tick()
        #expect(endOfDays(h) == 1)
        #expect(h.store.live.tracker.lastEndOfDay == DayKey(wed(18), calendar: .current))
    }

    @Test func theEndOfDayShowsOnlyOneTime() {
        let h = endOfHoursWithAPrompt()
        h.engine.skipTrackerPrompt()
        h.engine.tick()
        h.engine.closeTrackerEndOfDay()
        h.engine.openTrackerPanel()
        h.engine.closeTrackerPrompt()
        h.advance(minutes: 60)
        #expect(endOfDays(h) == 1)
    }

    @Test func aShortcutPromptOpenAtTheEndOfHoursAlsoWaits() {
        let h = EngineHarness.tracker(at: wed(17, 50))
        h.engine.skipTrackerPrompt()
        h.clock.advance(minutes: 9)
        h.engine.openTrackerPanel()
        h.advance(minutes: 1)
        #expect(endOfDays(h) == 0)
        h.engine.closeTrackerPrompt()
        h.engine.tick()
        #expect(endOfDays(h) == 1)
    }
}
