import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine time block status text")
struct EngineTimeBlockStatusTests {
    @Test func noBlockHasNoText() {
        let h = EngineHarness.quiet()
        #expect(h.engine.blockStatusText == nil)
    }

    @Test func plannedBlockShowsMinutesLeft() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 18)
        #expect(h.engine.blockStatusText == "12m")
        #expect(h.engine.status.text == "12m")
    }

    @Test func openBlockShowsMinutesSinceStart() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .open)
        h.advance(minutes: 42)
        #expect(h.engine.blockStatusText == "42m")
    }

    @Test func openBlockShowsHoursAndMinutes() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .open)
        h.advance(minutes: 125)
        #expect(h.engine.blockStatusText == "2h 5m")
    }

    @Test func textGoesAwayWhenTheBlockEnds() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .open)
        h.advance(minutes: 10)
        h.engine.endBlock()
        #expect(h.engine.blockStatusText == nil)
    }
}
