import SathiCore
import SwiftUI

struct ActivityPromptView: View {
    let state: TrackerPromptState
    let screen: ActivityPromptScreen
    let visible: CGRect
    var onDrop: () -> Bool = { true }
    @ObservedObject private var model: ActivityPromptModel

    init(
        state: TrackerPromptState, model: ActivityPromptModel? = nil,
        visibleHeight: CGFloat? = nil, visibleWidth: CGFloat? = nil, onDrop: @escaping () -> Bool = { true }
    ) {
        self.state = state
        visible = CGRect(
            x: 0, y: 0,
            width: visibleWidth ?? .greatestFiniteMagnitude,
            height: visibleHeight ?? .greatestFiniteMagnitude
        )
        self.onDrop = onDrop
        screen = ActivityPromptBuilder.screen(state)
        self.model = model ?? ActivityPromptModel(state)
    }

    private var goingAway: Bool { model.goingAway(on: screen) != nil }

    private var startedChoices: [Date] { goingAway ? [] : screen.startedChoices }

    private var commands: PromptCommands { PromptCommands(state: state, screen: screen, model: model) }

    private var size: CGSize { PromptFit.size(screen: visible, margin: UIMetrics.promptScreenMargin) }

    private var scrolls: Bool { PromptFit.scrolls(screen: visible, margin: UIMetrics.promptScreenMargin) }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.promptRadius, style: .continuous)
        VStack(spacing: 0) {
            PromptHeader(screen: screen, state: state, model: model, onSkip: commands.skip, onDrop: onDrop)
            Night.promptCardLine.frame(height: UIMetrics.promptBorder)
            HStack(spacing: 0) {
                if screen.todos.isEmpty {
                    PromptRecentPane(model: model, state: state)
                        .modifier(PromptDimmed(on: goingAway))
                } else {
                    PromptTodoPane(model: model, todos: screen.todos)
                }
                Night.promptCardLine.frame(width: UIMetrics.promptBorder)
                formColumn(commands)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: size.width, height: size.height)
        .background(Night.promptCard)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Night.promptBoxLine, lineWidth: UIMetrics.promptBorder))
        .environment(\.colorScheme, .dark)
    }

    private func formColumn(_ commands: PromptCommands) -> some View {
        VStack(alignment: .leading, spacing: UIMetrics.promptBodyGap) {
            PromptBodyFit(scrolls: scrolls) { main(commands) }
            if model.showsStarted, !startedChoices.isEmpty {
                PromptStartedBoxes(model: model, choices: startedChoices, calendar: state.calendar)
            }
            HStack(spacing: UIMetrics.promptFooterGap) {
                PromptStartedLink(model: model, choices: startedChoices, calendar: state.calendar)
                PromptFooter(screen: screen, commands: commands)
            }
        }
        .padding(UIMetrics.promptBodyPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func main(_ commands: PromptCommands) -> some View {
        VStack(alignment: .leading, spacing: UIMetrics.promptBodyGap) {
            if let ask = screen.markDone { PromptTodoDoneCard(ask: ask, actions: state.actions) }
            if let card = screen.card {
                PromptRunningCard(card: card, screen: screen, state: state, commands: commands)
                PromptOrSwitch()
            }
            PromptForm(model: model, state: state, screen: screen, onSubmit: commands.submit)
        }
    }
}
