import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine water thanks")
struct EngineWaterThanksTests {
    @Test func fullGlassCelebratesAsRefreshing() {
        let h = EngineHarness()
        h.engine.logWater(1)
        #expect(h.engine.celebration.title == "Ahh, refreshing!")
    }

    @Test func halfGlassCelebratesEverySip() {
        let h = EngineHarness()
        h.engine.logWater(0.5)
        #expect(h.engine.celebration.title == "Every sip counts!")
    }

    @Test func waterSeeYouNamesTheNextReminder() {
        let h = EngineHarness { $0.prefs.water.intervalMinutes = 30 }
        h.engine.logWater(1)
        #expect(h.engine.waterSeeYou == "See you in 30 min")
    }

    @Test func waterSeeYouSaysNiceOneWhenWaterIsOff() {
        let h = EngineHarness { $0.prefs.water.enabled = false }
        #expect(h.engine.waterSeeYou == "Nice one")
    }

    @Test func waterSeeYouWaitsForTheBreakWhilePaused() {
        let h = EngineHarness()
        h.engine.logWater(1)
        h.engine.pause(hours: 1)
        #expect(h.engine.waterSeeYou == "See you after your break")
    }

    @Test func waterOffWinsOverPause() {
        let h = EngineHarness { $0.prefs.water.enabled = false }
        h.engine.pause(hours: 1)
        #expect(h.engine.waterSeeYou == "Nice one")
    }
}
