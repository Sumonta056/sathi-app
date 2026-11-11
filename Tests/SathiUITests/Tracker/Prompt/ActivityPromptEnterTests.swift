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
}
