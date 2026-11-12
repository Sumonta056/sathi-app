import Foundation
import SathiCore
@testable import SathiUI
import Testing

@MainActor
@Suite("Activity prompt Enter")
struct ActivityPromptEnterTests {
    private func commands(_ s: TrackerPromptState, _ model: ActivityPromptModel) -> PromptCommands {
        PromptCommands(state: s, screen: ActivityPromptBuilder.screen(s), model: model)
    }

    @Test func enterInTheFieldAndTheStartKeyStartOnlyOnce() {
        let calls = PromptCalls()
        let s = Prompt.state(.whatNow, calls: calls)
        let model = ActivityPromptModel(s)
        commands(s, model).start()
        commands(s, model).start()
        #expect(calls.started.map(\.0.text) == ["Write spec"])
    }

    @Test func anEmptyStartDoesNotBlockTheNextStart() {
        let calls = PromptCalls()
        let s = Prompt.state(.whatNow, calls: calls) { $0.draft.text = "" }
        let model = ActivityPromptModel(s)
        commands(s, model).start()
        model.draft.text = "Review"
        commands(s, model).start()
        #expect(calls.started.map(\.0.text) == ["Review"])
    }

    @Test func anEventAnswersYesOnlyOnce() {
        let calls = PromptCalls()
        let event = CalendarEventInfo(id: "e1", title: "Standup", start: Prompt.now, end: Prompt.now.addingTimeInterval(900), calendarID: "work")
        let s = Prompt.state(.eventAsk, calls: calls) { $0.event = event }
        let model = ActivityPromptModel(s)
        commands(s, model).start()
        commands(s, model).start()
        #expect(calls.answers == [true])
    }

    @Test func enterWithEmptyTextAndACardKeeps() {
        let calls = PromptCalls()
        let s = Reasons.withKeep(.stillOnIt, calls: calls)
        let model = ActivityPromptModel(s)
        model.draft.text = ""
        commands(s, model).submit()
        #expect(calls.stillOn == [15])
        #expect(calls.started.isEmpty)
    }

    @Test(arguments: [(PromptKind.whatNow, "continue"), (.center, "close"), (.welcomeBack, "back")])
    func enterWithEmptyTextCallsTheCardKeep(_ kind: PromptKind, _ action: String) {
        let calls = PromptCalls()
        let s = Reasons.withKeep(kind, calls: calls)
        let model = ActivityPromptModel(s)
        model.draft.text = ""
        commands(s, model).submit()
        let done = calls.calls + calls.continued.map { _ in "continue" }
        #expect(done == [action])
        #expect(calls.started.isEmpty)
    }

    @Test func enterWithATypedNameAndACardStarts() {
        let calls = PromptCalls()
        let s = Reasons.withKeep(.stillOnIt, calls: calls)
        let model = ActivityPromptModel(s)
        model.draft.text = "Review"
        commands(s, model).submit()
        #expect(calls.started.map(\.0.text) == ["Review"])
        #expect(calls.stillOn.isEmpty)
    }

    @Test func enterWithNoCardAndEmptyTextDoesNothing() {
        let calls = PromptCalls()
        let s = Prompt.state(.whatNow, calls: calls) { $0.draft.text = "" }
        commands(s, ActivityPromptModel(s)).submit()
        #expect(calls.started.isEmpty)
        #expect(calls.continued.isEmpty)
        #expect(calls.calls.isEmpty)
    }

    @Test func enterWithNoCardStarts() {
        let calls = PromptCalls()
        let s = Prompt.state(.whatNow, calls: calls)
        commands(s, ActivityPromptModel(s)).submit()
        #expect(calls.started.map(\.0.text) == ["Write spec"])
    }

    @Test func startIsAnOutlineWhileTheTextIsEmptyAndACardShows() {
        let s = Reasons.withKeep(.stillOnIt)
        let model = ActivityPromptModel(s)
        model.draft.text = ""
        #expect(!commands(s, model).startIsPrimary)
        model.draft.text = "Review"
        #expect(commands(s, model).startIsPrimary)
    }

    @Test(arguments: [PromptKind.whatNow, .eventAsk])
    func startIsAlwaysFilledWithoutACard(_ kind: PromptKind) {
        let s = kind == .eventAsk ? Reasons.withKeep(.eventAsk) : Prompt.state(.whatNow)
        let model = ActivityPromptModel(s)
        model.draft.text = ""
        #expect(commands(s, model).startIsPrimary)
    }

    @Test func startIsFilledWhileGoingAway() {
        let s = Reasons.withKeep(.center)
        let model = ActivityPromptModel(s)
        model.draft.text = ""
        model.turnAway(true)
        model.pickAway(named: "Sleep")
        #expect(commands(s, model).startIsPrimary)
    }

    @Test func enterInTheFieldAndTheKeepKeyKeepOnlyOnce() {
        let calls = PromptCalls()
        let s = Reasons.withKeep(.welcomeBack, calls: calls)
        let model = ActivityPromptModel(s)
        model.draft.text = ""
        commands(s, model).submit()
        commands(s, model).keep()
        #expect(calls.calls == ["back"])
    }

    @Test func spacesOnlyKeepStartAnOutline() {
        let s = Reasons.withKeep(.stillOnIt)
        let model = ActivityPromptModel(s)
        model.draft.text = "   "
        #expect(!commands(s, model).startIsPrimary)
        #expect(commands(s, model).entersKeep)
    }
}
