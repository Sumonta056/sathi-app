import SathiCore
import SwiftUI

struct ActivityPromptView: View {
    let state: TrackerPromptState
    let screen: ActivityPromptScreen
    @ObservedObject private var model: ActivityPromptModel

    init(state: TrackerPromptState, model: ActivityPromptModel? = nil) {
        self.state = state
        screen = ActivityPromptBuilder.screen(state)
        self.model = model ?? ActivityPromptModel(state)
    }

    private var goingAway: Bool { model.goingAway(on: screen) != nil }

    private var startedChoices: [Date] { goingAway ? [] : screen.startedChoices }

    private var commands: PromptCommands { PromptCommands(state: state, screen: screen, model: model) }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.promptRadius, style: .continuous)
        VStack(spacing: 0) {
            PromptHeader(screen: screen, state: state, model: model, onSkip: commands.skip)
            Night.promptCardLine.frame(height: UIMetrics.promptBorder)
            HStack(spacing: 0) {
                PromptRecentPane(model: model, state: state)
                    .modifier(PromptDimmed(on: goingAway))
                Night.promptCardLine.frame(width: UIMetrics.promptBorder)
                formColumn(commands)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: UIMetrics.activityPromptWidth)
        .background(Night.promptCard)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Night.promptBoxLine, lineWidth: UIMetrics.promptBorder))
        .environment(\.colorScheme, .dark)
    }

    private func formColumn(_ commands: PromptCommands) -> some View {
        VStack(alignment: .leading, spacing: UIMetrics.promptBodyGap) {
            if let card = screen.card {
                PromptRunningCard(card: card, screen: screen, state: state, commands: commands)
                PromptOrSwitch()
            }
            PromptForm(model: model, state: state, screen: screen, onSubmit: commands.submit)
            Spacer(minLength: 0)
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
}
