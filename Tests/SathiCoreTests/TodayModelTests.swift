import Combine
import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Today model")
struct TodayModelTests {
    private func settle() async {
        await withCheckedContinuation { c in DispatchQueue.main.async { c.resume() } }
    }

    private func breathing() -> EngineHarness {
        let h = EngineHarness(at: day(2026, 3, 4, 10, 0).addingTimeInterval(10)) {
            $0.prefs.water.enabled = false
            $0.prefs.reading.enabled = false
            $0.prefs.gym.enabled = false
            $0.prefs.meditation.sessionMinutes = 5
            $0.prefs.tracker.isOn = true
        }
        h.engine.startActivity(ActivityDraft(text: "Code review", length: .minutes(30)))
        h.engine.startMeditation()
        return h
    }

    private func tickSeconds(_ h: EngineHarness, _ seconds: Int) async {
        for _ in 0 ..< seconds {
            h.clock.now = h.clock.now.addingTimeInterval(1)
            h.engine.tick()
            await settle()
        }
    }

    @Test func attachBuildsTheScreenAtOnce() {
        let h = EngineHarness()
        let model = TodayModel()
        #expect(model.screen == nil)
        model.attach(h.engine)
        #expect(model.screen == h.engine.todayScreen)
    }

    @Test func tenOneSecondTicksInsideAMinutePublishNothing() async {
        let h = breathing()
        let model = TodayModel()
        model.attach(h.engine)
        var published = 0
        let bag = model.$screen.dropFirst().sink { _ in published += 1 }
        await tickSeconds(h, 10)
        #expect(published == 0)
        bag.cancel()
    }

    @Test func crossingTheMinutePublishesOnce() async {
        let h = breathing()
        let model = TodayModel()
        model.attach(h.engine)
        var published = 0
        let bag = model.$screen.dropFirst().sink { _ in published += 1 }
        await tickSeconds(h, 10)
        await tickSeconds(h, 40)
        #expect(published == 1)
        bag.cancel()
    }

    @Test func loggingAGlassPublishesAtOnce() async {
        let h = EngineHarness(at: day(2026, 3, 4, 10, 0).addingTimeInterval(10)) {
            $0.prefs.reading.enabled = false
            $0.prefs.meditation.enabled = false
            $0.prefs.gym.enabled = false
        }
        let model = TodayModel()
        model.attach(h.engine)
        var published = 0
        let bag = model.$screen.dropFirst().sink { _ in published += 1 }
        h.engine.logWater(1)
        await settle()
        #expect(published >= 1)
        #expect(model.screen?.buddies.first { $0.habit == .water }?.total == "1")
        bag.cancel()
    }

    @Test func detachStopsUpdates() async {
        let h = EngineHarness(at: day(2026, 3, 4, 10, 0).addingTimeInterval(10))
        let model = TodayModel()
        model.attach(h.engine)
        model.detach()
        h.engine.logWater(1)
        await settle()
        #expect(model.screen?.buddies.first { $0.habit == .water }?.total == "0")
    }
}
