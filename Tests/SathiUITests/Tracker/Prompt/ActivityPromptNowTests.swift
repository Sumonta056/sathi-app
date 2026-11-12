import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity prompt Started: Now")
struct ActivityPromptNowTests {
    private func at(_ h: Int, _ m: Int = 0) -> Date { day(2026, 3, 4, h, m) }

    private func stillOnItAtTen52() -> EngineHarness {
        let h = EngineHarness.tracker(at: at(10)) { $0.prefs.tracker.askEveryMinutes = 15 }
        h.engine.startActivity(ActivityDraft(text: "Spec", category: "Coding", length: .minutes(30)))
        h.advance(minutes: 30)
        h.engine.stillOnIt(minutes: 15)
        h.advance(minutes: 15)
        h.clock.advance(minutes: 7)
        return h
    }

    @Test func startWithNowUsesTheTimeOfTheAnswer() throws {
        let h = stillOnItAtTen52()
        let state = try #require(h.engine.trackerPromptState(.stillOnIt))
        let model = ActivityPromptModel(state)
        model.draft.text = "Next"
        h.clock.advance(minutes: 40)
        try Prompt.tap(Prompt.view(state, model: model), "tracker.start")
        #expect(h.engine.runningActivity?.text == "Next")
        #expect(h.engine.runningActivity?.start == at(11, 32))
        #expect(h.activities.all.first { $0.text == "Spec" }?.end == at(11, 32))
    }

    @Test func startWithAPickedTimeKeepsThatTime() throws {
        let h = stillOnItAtTen52()
        let state = try #require(h.engine.trackerPromptState(.stillOnIt))
        let model = ActivityPromptModel(state)
        model.draft.text = "Next"
        model.started = at(10, 40)
        h.clock.advance(minutes: 40)
        try Prompt.tap(Prompt.view(state, model: model), "tracker.start")
        #expect(h.engine.runningActivity?.start == at(10, 40))
    }

    @Test func keepAndSkipWithNowSendNoTime() throws {
        let calls = PromptCalls()
        let earlier = Prompt.now.addingTimeInterval(-600)
        var s = Reasons.withKeep(.whatNow, calls: calls)
        s.switchTimes = [earlier, Prompt.now]
        let model = ActivityPromptModel(s)
        try Prompt.tap(Prompt.view(s, model: model), "prompt.keep")
        try Prompt.tap(Prompt.view(s, model: model), "tracker.skip")
        #expect(calls.continued == [nil])
        #expect(calls.skipped == [nil])
    }

    @Test func aRefusedStartLeavesStartWorking() throws {
        let calls = PromptCalls()
        calls.startWorks = false
        let s = Prompt.state(.whatNow, calls: calls)
        let model = ActivityPromptModel(s)
        try Prompt.tap(Prompt.view(s, model: model), "tracker.start")
        #expect(!model.answered)
        calls.startWorks = true
        try Prompt.tap(Prompt.view(s, model: model), "tracker.start")
        #expect(calls.started.count == 2)
        #expect(model.answered)
    }

    @Test func theEngineRefusesAStartWhenTheTrackerIsOff() {
        let h = EngineHarness.tracker(at: at(10)) { $0.prefs.tracker.isOn = false }
        #expect(!h.engine.startActivity(ActivityDraft(text: "Spec")))
        #expect(EngineHarness.tracker(at: at(10)).engine.startActivity(ActivityDraft(text: "Spec")))
    }
}
