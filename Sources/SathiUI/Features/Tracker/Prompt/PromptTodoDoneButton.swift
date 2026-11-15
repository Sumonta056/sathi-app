import SathiCore
import SwiftUI

struct PromptTodoDoneButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.promptButtonRadius, style: .continuous)
        Button(action: action) {
            Text(verbatim: label)
                .font(Typography.tracker(UIMetrics.promptButtonFont, .semibold))
                .foregroundStyle(Night.text)
                .lineLimit(1)
                .padding(.horizontal, UIMetrics.promptSkipPadding)
                .frame(height: UIMetrics.promptButtonHeight)
                .overlay(shape.strokeBorder(Night.promptBoxLine, lineWidth: UIMetrics.promptBorder))
                .contentShape(shape)
                .accessibilityIdentifier("prompt.todoDone")
        }
        .buttonStyle(TrackerPressStyle())
    }
}
