import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity prompt actions")
struct ActivityPromptActionsTests {
    private let earlier = Prompt.now.addingTimeInterval(-600)
    private let middle = Prompt.now.addingTimeInterval(-300)

    private func tap(_ s: TrackerPromptState, _ id: String) throws {
        try Prompt.tap(Prompt.view(s), id)
    }

    @Test func askStartStartsTheDraftWithNoSwitchTime() throws {
        let calls = PromptCalls()
        try tap(Prompt.state(.whatNow, calls: calls), "tracker.start")
        #expect(calls.started.map(\.0.text) == ["Write spec"])
        #expect(calls.started.map(\.1) == [nil])
    }

    @Test func emptyTextDoesNotStart() throws {
        let calls = PromptCalls()
        try tap(Prompt.state(.whatNow, calls: calls) { $0.draft.text = "  " }, "tracker.start")
        #expect(calls.started.isEmpty)
    }

    @Test func askAfterDoneStartsAndSkipsAtThePickedTime() throws {
        let calls = PromptCalls()
        let s = Prompt.state(.whatNow, calls: calls) { $0.switchTimes = [earlier, middle, Prompt.now] }
        try tap(s, "tracker.start")
        let model = ActivityPromptModel(s)
        try Prompt.tap(Prompt.view(s, model: model), "prompt.started")
        try Prompt.tap(Prompt.view(s, model: model), "prompt.started.0")
        try Prompt.tap(Prompt.view(s, model: model), "tracker.skip")
        #expect(calls.started.map(\.1) == [nil])
        #expect(calls.skipped == [earlier])
    }

    @Test func askKeepContinuesTheLastActivity() throws {
        let calls = PromptCalls()
        try tap(Reasons.withKeep(.whatNow, calls: calls), "prompt.keep")
        #expect(calls.continued == [nil])
    }

    @Test func shortcutKeepAndSkipBothClose() throws {
        let calls = PromptCalls()
        let s = Reasons.withKeep(.center, calls: calls)
        try tap(s, "prompt.keep")
        try tap(s, "tracker.close")
        try tap(s, "prompt.dismiss")
        #expect(calls.calls == ["close", "close", "close"])
        try tap(s, "tracker.start")
        #expect(calls.started.count == 1)
    }

    @Test func endsKeepGoingAsksAgainAfterAskEvery() throws {
        let calls = PromptCalls()
        try tap(Reasons.withKeep(.stillOnIt, calls: calls), "prompt.keep")
        #expect(calls.stillOn == [15])
    }

    @Test func endsLateKeepIsStillOnIt() throws {
        let calls = PromptCalls()
        let s = Prompt.state(.stillOnIt, calls: calls) {
            $0.running = Reasons.running()
            $0.waitedMinutes = 12
        }
        try tap(s, "prompt.keep")
        #expect(calls.calls == ["stillLate"])
    }

    @Test func endsSkipChangesNothing() throws {
        let calls = PromptCalls()
        let s = Prompt.state(.stillOnIt, calls: calls) {
            $0.running = Reasons.running()
            $0.switchTimes = [earlier, Prompt.now]
        }
        try tap(s, "tracker.skip")
        #expect(calls.skipped == [nil])
    }

    @Test func endsSwitchEndsTheOldOneAtThePickedTime() throws {
        let calls = PromptCalls()
        let s = Prompt.state(.stillOnIt, calls: calls) {
            $0.running = Reasons.running()
            $0.switchTimes = [earlier, Prompt.now]
        }
        let model = ActivityPromptModel(s)
        model.started = earlier
        try Prompt.tap(Prompt.view(s, model: model), "tracker.start")
        #expect(calls.started.map(\.1) == [earlier])
    }

    @Test func backKeepGoesBackAndSkipKeepsTheAway() throws {
        let calls = PromptCalls()
        let s = Reasons.withKeep(.welcomeBack, calls: calls)
        try tap(s, "prompt.keep")
        try tap(s, "tracker.close")
        #expect(calls.calls == ["back", "close"])
    }

    @Test(arguments: [(AwayCause.idle, true), (.asleep, false), (.locked, false)])
    func iWasHereOnlyAfterIdle(_ cause: AwayCause, _ shown: Bool) throws {
        let calls = PromptCalls()
        let s = Prompt.state(.welcomeBack, calls: calls) {
            $0.away = AwaySpan(start: Prompt.now.addingTimeInterval(-900), end: Prompt.now, cause: cause)
        }
        let sut = try Prompt.view(s)
        #expect(Prompt.has(sut, "tracker.here") == shown)
        if shown {
            try Prompt.tap(sut, "tracker.here")
            #expect(calls.calls == ["here"])
        }
    }

    @Test func eventLogItPicksTheCategoryThenAnswersYes() throws {
        let calls = PromptCalls()
        let s = Reasons.withKeep(.eventAsk, calls: calls)
        let model = ActivityPromptModel(s)
        try Prompt.tap(Prompt.view(s, model: model), "tracker.category.Review")
        try Prompt.tap(Prompt.view(s, model: model), "tracker.start")
        #expect(calls.calls == ["category:Review", "answer:true"])
        #expect(calls.started.isEmpty)
    }

    @Test func eventSkipAnswersNo() throws {
        let calls = PromptCalls()
        try tap(Reasons.withKeep(.eventAsk, calls: calls), "tracker.no")
        #expect(calls.answers == [false])
    }

    @Test func startIsTheDefaultKeyAndSkipIsEsc() throws {
        let sut = try Prompt.view(Prompt.state(.whatNow))
        let start = try sut.find(viewWithAccessibilityIdentifier: "tracker.start").find(ViewType.Button.self, relation: .parent)
        let skip = try sut.find(viewWithAccessibilityIdentifier: "tracker.skip").find(ViewType.Button.self, relation: .parent)
        #expect(try start.modifier(PromptKey.self).actualView().shortcut == .defaultAction)
        #expect(try skip.modifier(PromptKey.self).actualView().shortcut == .cancelAction)
    }

    @Test func theStartedLinkIsHiddenWithOnlyNow() throws {
        let sut = try Prompt.view(Prompt.state(.whatNow))
        #expect(!Prompt.has(sut, "prompt.started"))
        #expect(Prompt.hasText(sut, "Esc: Skip"))
    }

    @Test func theStartedLinkOpensTheBoxesAndFollowsThePick() throws {
        let s = Prompt.state(.whatNow) { $0.switchTimes = [earlier, middle, Prompt.now] }
        let model = ActivityPromptModel(s)
        let sut = try Prompt.view(s, model: model)
        #expect(try Prompt.buttonText(sut, "prompt.started") == ["Started: Now · change"])
        #expect(!Prompt.hasText(sut, "It really started at"))
        try Prompt.tap(sut, "prompt.started")
        let open = try Prompt.view(s, model: model)
        #expect(Prompt.hasText(open, "It really started at"))
        #expect(try Prompt.boxIsOn(open, "prompt.started.2"))
        try Prompt.tap(open, "prompt.started.1")
        let label = "Started: " + Copywriter.trackerClock(middle, calendar: Prompt.calendar) + " · change"
        #expect(try Prompt.buttonText(Prompt.view(s, model: model), "prompt.started") == [label])
    }
}
