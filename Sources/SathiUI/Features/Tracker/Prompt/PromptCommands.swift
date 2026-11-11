import SathiCore
import SwiftUI

@MainActor
struct PromptCommands {
    let state: TrackerPromptState
    let screen: ActivityPromptScreen
    let model: ActivityPromptModel

    private var actions: TrackerPromptActions { state.actions }

    func start() {
        guard !model.answered else { return }
        switch screen.reason {
        case .event:
            model.answered = true
            if let category = model.draft.category { actions.pickEventCategory(category) }
            actions.answerEvent(true)
        case .ask, .shortcut, .ends, .back:
            guard let draft = model.draft.committed else { return }
            model.answered = true
            actions.start(draft, model.started)
        }
    }

    func keep() {
        switch screen.keep {
        case .continueLast: actions.continueLast(model.started)
        case .keep: actions.close()
        case let .keepGoing(minutes): actions.stillOn(minutes)
        case .stillOnLate: actions.stillOnLate()
        case .backTo: actions.backToLast()
        case nil: break
        }
    }

    func skip() {
        switch screen.skip {
        case .skip: actions.skip(screen.reason == .ends ? nil : model.started)
        case .close: actions.close()
        case .answerNo: actions.answerEvent(false)
        }
    }
}
