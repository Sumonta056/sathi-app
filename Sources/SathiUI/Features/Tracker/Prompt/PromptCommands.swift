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
        if let pick = model.goingAway(on: screen) {
            model.answered = true
            actions.goAway(pick.place, pick.name)
            return
        }
        switch screen.reason {
        case .event:
            model.answered = true
            if let category = model.draft.category { actions.pickEventCategory(category) }
            actions.answerEvent(true)
        case .ask, .shortcut, .ends, .back:
            guard let draft = model.draft.committed else { return }
            model.answered = actions.start(draft, model.switchAt)
        }
    }

    var startIsPrimary: Bool {
        screen.card == nil || model.draft.committed != nil || model.goingAway(on: screen) != nil
    }

    var entersKeep: Bool { !startIsPrimary && screen.keep != nil }

    func submit() {
        if entersKeep { keep() } else { start() }
    }

    func keep() {
        guard !model.answered, screen.keep != nil else { return }
        model.answered = true
        switch screen.keep {
        case .continueLast: actions.continueLast(model.switchAt)
        case .keep: actions.close()
        case let .keepGoing(minutes): actions.stillOn(minutes)
        case .stillOnLate: actions.stillOnLate()
        case .backTo: actions.backToLast()
        case nil: break
        }
    }

    func skip() {
        switch screen.skip {
        case .skip: actions.skip(screen.reason == .ends ? nil : model.switchAt)
        case .close: actions.close()
        case .answerNo: actions.answerEvent(false)
        }
    }
}
