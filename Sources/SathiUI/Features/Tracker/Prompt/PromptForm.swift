import SathiCore
import SwiftUI

struct PromptForm: View {
    @ObservedObject var model: ActivityPromptModel
    let state: TrackerPromptState
    let screen: ActivityPromptScreen
    let onSubmit: () -> Void
    @Environment(\.controlActiveState) private var active

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.promptBodyGap) {
            field
            VStack(alignment: .leading, spacing: UIMetrics.promptRowGap) {
                PromptBoxRow(label: Copywriter.trackerCategory) { PromptCategoryBoxes(model: model, categories: state.categories) }
                PromptBoxRow(label: Copywriter.trackerFor) { PromptLengthBoxes(model: model, state: state) }
                if !isEvent {
                    PromptBoxRow(label: Copywriter.trackerAskMe) { PromptAskBoxes(model: model) }
                }
                PromptBoxRow(label: Copywriter.trackerCalendar) { PromptCalendarBoxes(model: model, state: state, screen: screen) }
                if !isEvent {
                    PromptBoxRow(label: Copywriter.activityPromptQuiet, labelTop: 0) { PromptQuietRow(model: model) }
                }
            }
        }
    }

    private var isEvent: Bool { screen.reason == .event }

    private var field: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.promptFieldRadius, style: .continuous)
        let focused = active == .key
        return LazyTextField(
            placeholder: Copywriter.activityPromptField, text: $model.draft.text, startsEditing: !isEvent, onSubmit: onSubmit,
            font: Typography.tracker(UIMetrics.promptFieldFont, .semibold)
        )
        .modifier(QuickTextLimit(text: $model.draft.text, limit: Limits.activityTextMax))
        .padding(.horizontal, UIMetrics.promptFieldPadding - UIMetrics.timeButtonPadding.leading)
        .frame(height: UIMetrics.promptFieldHeight)
        .background(shape.fill(Night.promptBox))
        .overlay(shape.strokeBorder(
            focused ? Night.tracker : Night.promptBoxLine,
            lineWidth: focused ? UIMetrics.promptFieldFocusBorder : UIMetrics.promptBorder
        ))
        .disabled(isEvent)
        .accessibilityIdentifier("prompt.field")
    }
}
